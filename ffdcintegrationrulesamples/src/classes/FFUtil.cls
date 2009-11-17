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
	// Simple cache of the users current company (do not directly expose this partially loaded object)
	private static c2g__codaCompany__c s_currentCompany;
	
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
			[select RecordType.Name, c2g__TaxCode__c from c2g__codaCompany__c where OwnerId in :groupIds];
		
		// Ensure the user has a single current company
		if(companies.size() == 0)
			throw new FFUtilException('Current company has not been set for this user');
		if(companies.size() > 1)
			throw new FFUtilException('This operation is not valid in multiple company mode'); 
		s_currentCompany = companies[0];
		return s_currentCompany;
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
	 * Sets a test company (for use during Apex Unit tests only)
	 **/	
	public static void setTestCompany(c2g__codaCompany__c company)
	{
		s_currentCompany = company;
	}

	/**
	 * General exceptions from this class
	 **/	
	public class FFUtilException extends Exception
	{
		
	}
}