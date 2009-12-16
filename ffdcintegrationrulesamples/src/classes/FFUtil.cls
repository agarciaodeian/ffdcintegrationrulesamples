/**
 * Copyright (c) 2009, FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/
public class FFUtil 
{	
	/**
	 * Due Date Rules
	 **/
	public static String BASE_DATE_END_OF_NEXT_MONTH = 'End of next month';
	public static String BASE_DATE_START_OF_NEXT_MONTH = 'Start of next month';
	public static String BASE_DATE_INVOICE_DATE = 'Invoice date';
	
	/**
	 * Special Periods
	 **/
	public static final String OPENING_PERIOD = '000';
	public static final String ADJUSTMENT_PERIOD = '100';
	public static final String CLOSING_PERIOD = '101';	
	
	// Simple cache of the users current company (do not directly expose this partially loaded object)
	private static c2g__codaCompany__c s_currentCompany;
	private static List<c2g__codaPeriod__c> s_currentCompanyPeriods;
	
	/**
	 * Resolve current company for current user
	 **/
	private static c2g__codaCompany__c getCurrentCompany()
	{
		// Cached resulted from previous call?
		if(s_currentCompany!=null)
			return s_currentCompany;
			
		// Query users group membership and xref with companies to determine current subscription
		List<ID> groupIds = new List<ID>();
		for(GroupMember member : [select GroupId from GroupMember where Group.Type = 'Queue' and UserOrGroupId = :UserInfo.getUserId()])
			groupIds.add(member.GroupId);				
		c2g__codaCompany__c[] companies = 
			[select RecordType.Name, Id, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c from c2g__codaCompany__c where OwnerId in :groupIds];
		
		// Ensure the user has a single current company
		if(companies.size() == 0)
			throw new FFUtilException('Current company has not been set for this user');
		if(companies.size() > 1)
			throw new FFUtilException('This operation is not valid in multiple company mode'); 
		s_currentCompany = companies[0];
		
        // Load Periods for this company
        s_currentCompanyPeriods = 
        	[select Id, c2g__StartDate__c, c2g__EndDate__c, c2g__PeriodNumber__c from c2g__codaPeriod__c where c2g__OwnerCompany__c = :s_currentCompany.Id];
                    		
		return s_currentCompany;
	}
	
	/**
	 * Resolve periods for the current company
	 **/
	private static List<c2g__codaPeriod__c> getPeriods()
	{
		c2g__codaCompany__c company = getCurrentCompany();
		return s_currentCompanyPeriods;
	}
	
	/**
	 * Returns true if the current users company tax mode is VAT
	 *   (errors if no current company or multiple company mode enabled for the user)
	 **/ 
	public static boolean isCurrentCompanyVAT()
	{	
		return getCurrentCompany().RecordType.Name.equals('VAT');		
	}

	/**
	 * Returns true if the current users company tax mode is SUT
	 *   (errors if no current company or multiple company mode enabled for the user)
	 **/ 
	public static boolean isCurrentCompanySalesAndUse()
	{	
		return getCurrentCompany().RecordType.Name.equals('SUT');		
	}
	
	/**
	 * Returns the ID for the default company Tax Code
	 **/
	public static ID getDefaultCompanyTaxCode()
	{
		return getCurrentCompany().c2g__TaxCode__c;
	}
	
	/**
	 * Returns the applicable period for the given date?
	 **/
	public static ID getPeriodIDByDate(Date periodDate)
	{
       	for(c2g__codaPeriod__c queryPeriod : getPeriods())
		{
			if((queryPeriod.c2g__StartDate__c <= periodDate) &&
			   (queryPeriod.c2g__EndDate__c >= periodDate) &&
			   !queryPeriod.c2g__PeriodNumber__c.equals(OPENING_PERIOD) &&
			   !queryPeriod.c2g__PeriodNumber__c.equals(ADJUSTMENT_PERIOD) &&
			   !queryPeriod.c2g__PeriodNumber__c.equals(CLOSING_PERIOD))
			   	return queryPeriod.Id;
		}
		return null;
	}

	/**
	 * Sets a test company and periods (for use during Apex Unit tests only)
	 **/	
	public static void setTestCompany(c2g__codaCompany__c company)
	{
		s_currentCompany = company;
        s_currentCompanyPeriods = 
        	[select Id, c2g__StartDate__c, c2g__EndDate__c, c2g__PeriodNumber__c from c2g__codaPeriod__c where c2g__OwnerCompany__c = :s_currentCompany.Id];
	}

	/**
	 * Calculates a Due Date from the given rule
	 **/
	public static Date calculateDueDate(Date invoiceDate, String baseDateRule, Decimal daysOffset)
	{
		Integer numberOfDays = 0;
		Date dueDate = null;
		
		if(invoiceDate == null)
			return null;
		
		if(baseDateRule == BASE_DATE_INVOICE_DATE)
		{
			dueDate = invoiceDate.addDays(daysOffset.intValue());
		}
		else if(baseDateRule == BASE_DATE_START_OF_NEXT_MONTH)
		{
			dueDate = invoiceDate.toStartOfMonth();
			dueDate = dueDate.addMonths(1);
			dueDate = dueDate.addDays(daysOffset.intValue());
		}
		else if (baseDateRule == BASE_DATE_END_OF_NEXT_MONTH)
		{
			//End of next month
			dueDate = invoiceDate.toStartOfMonth();
			dueDate = dueDate.addMonths(1);
			numberOfDays = Date.daysInMonth(dueDate.year(),dueDate.month());
			dueDate = dueDate.addDays(numberOfDays-1);
			dueDate = dueDate.addDays(daysOffset.intValue());
		}
			
		return dueDate;
	}

	/**
	 * Calculates a Due Date from the rule defined on the currency users company
	 **/	
	public static Date calculateCompanyDueDate(Date invoiceDate)
	{
		if(invoiceDate == null)
			return null;
		c2g__codaCompany__c company = getCurrentCompany();
		if(company.c2g__CODABaseDate1__c==null)
			return invoiceDate;
		String baseDate = company.c2g__CODABaseDate1__c;
		Integer offsetdays = (company.c2g__CODADaysOffset1__c == null) 
			? 0 : company.c2g__CODADaysOffset1__c.intValue();
		return FFUtil.calculateDueDate(invoiceDate,baseDate,offsetdays);		
	}

	/**
	 * General exceptions from this class
	 **/	
	public class FFUtilException extends Exception
	{
		
	}
}