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
trigger WorkOrderDefaulting on Work_Order__c (before insert, before update, after update) 
{
    if(Trigger.isBefore)
    {
		// VAT
		if(FFUtil.isCurrentCompanyVAT())
		{
			// Clear tax fields 	    	
	        for(Work_Order__c workOrder : Trigger.new)
	        {
	            // Clear tax codes (work order line item trigger will do all the work in VAT case)
	            workOrder.Tax_Code_1__c = null;
	            workOrder.Tax_Code_2__c = null;
	            workOrder.Tax_Code_3__c = null;
	            workOrder.Tax_Rate_1__c = 0;
	            workOrder.Tax_Rate_2__c = 0;
	            workOrder.Tax_Rate_3__c = 0;            
	        }
		}
		// SUT
		else
		{
	        if(Trigger.isUpdate || Trigger.isInsert)
	        {
	            // Load Accounts for given Work Orders
	            Map<ID, ID> accountIds = new Map<ID, ID>();
	            for(Work_Order__c workOrder : Trigger.new)
	                if(workOrder.Customer_Account__c!=null)
	                    accountIds.put(workOrder.Customer_Account__c, workOrder.Customer_Account__c);
	            List<Account> accounts = 
	                [select Id, c2g__CODASalesTaxStatus__c, c2g__CODATaxCode1__c, c2g__CODATaxCode2__c, c2g__CODATaxCode3__c 
	                    from Account where Id in :accountIds.values()];
	            Map<ID, Account> accountById = new Map<ID, Account>();
	            for(Account account : accounts)
	                accountById.put(account.Id, account);
	                
	            // Resolve Tax Codes
	            Date minCompletionDate = null;
	            Date maxCompletionDate = null;
	            Map<ID, ID> taxCodeIds = new Map<ID, ID>();
	            for(Work_Order__c workOrder : Trigger.new)
	            {
	                // Account? 
	                if(workOrder.Customer_Account__c==null)
	                {
	                    // Clear tax codes if no account
	                    workOrder.Tax_Code_1__c = null;
	                    workOrder.Tax_Code_2__c = null;
	                    workOrder.Tax_Code_3__c = null;
	                    continue;           
	                }       
	                
	                // Default Tax Codes from Account
	                Account account = accountById.get(workOrder.Customer_Account__c);
	                workOrder.Tax_Code_1__c = account.c2g__CODATaxCode1__c;
	                workOrder.Tax_Code_2__c = account.c2g__CODATaxCode2__c;
	                workOrder.Tax_Code_3__c = account.c2g__CODATaxCode3__c;
	                // Log Tax Code ID's used
	                if(workOrder.Tax_Code_1__c!=null)
	                    taxCodeIds.put(workOrder.Tax_Code_1__c, workOrder.Tax_Code_1__c);
	                if(workOrder.Tax_Code_2__c!=null)
	                    taxCodeIds.put(workOrder.Tax_Code_2__c, workOrder.Tax_Code_2__c);
	                if(workOrder.Tax_Code_3__c!=null)
	                    taxCodeIds.put(workOrder.Tax_Code_3__c, workOrder.Tax_Code_3__c);
	                    
	                // Establish the range of completion dates in which to calculate tax for this batch
	                if(workOrder.Completion_Date__c!=null)
	                {
	                    if(workOrder.Completion_Date__c < minCompletionDate)
	                        minCompletionDate = workOrder.Completion_Date__c;
	                    if(workOrder.Completion_Date__c > maxCompletionDate)
	                        maxCompletionDate = workOrder.Completion_Date__c;               
	                }
	            }
	            
	            // Load applicable subset of Tax Rates to match against completion dates
	            List<c2g__codaTaxCode__c> taxCodes = 
	                [select Name, Id, 
	                    (select Id, c2g__Rate__c, c2g__StartDate__c From c2g__TaxRates__r
	                        where c2g__StartDate__c >= :minCompletionDate and
	                              c2g__StartDate__c <= :maxCompletionDate 
	                        order by c2g__StartDate__c desc) 
	                    from c2g__codaTaxCode__c
	                    where Id in :taxCodeIds.values()];
	            Map<ID, c2g__codaTaxCode__c> taxCodesById = new Map<ID, c2g__codaTaxCode__c>();
	            for(c2g__codaTaxCode__c taxCode : taxCodes)
	                taxCodesById.put(taxCode.Id, taxCode);
	                
	            // Now caluclate tax rates
	            for(Work_Order__c workOrder : Trigger.new)
	            {
	                // Default to zero 
	                workOrder.Tax_Rate_1__c = 0;
	                workOrder.Tax_Rate_2__c = 0;
	                workOrder.Tax_Rate_3__c = 0;
	                // Account? Or Tax Exempt Accounts?
	                Account account = accountById.get(workOrder.Customer_Account__c);
	                if(account==null || account.c2g__CODASalesTaxStatus__c == 'Exempt')
	                    continue;
	                // Resolve rate according to completion date of work item               
	                if(workOrder.Tax_Code_1__c!=null)
	                {
	                    for(c2g__codaTaxRate__c taxRate : taxCodesById.get(workOrder.Tax_Code_1__c).c2g__TaxRates__r)
	                    {
	                        if(taxRate.c2g__StartDate__c <= workOrder.Completion_Date__c)
	                        {
	                             workOrder.Tax_Rate_1__c = taxRate.c2g__Rate__c;
	                             break; 
	                        }
	                    }
	                }
	                if(workOrder.Tax_Code_2__c!=null)
	                {
	                    for(c2g__codaTaxRate__c taxRate : taxCodesById.get(workOrder.Tax_Code_2__c).c2g__TaxRates__r)
	                    {
	                        if(taxRate.c2g__StartDate__c <= workOrder.Completion_Date__c)
	                        {
	                             workOrder.Tax_Rate_2__c = taxRate.c2g__Rate__c;
	                             break; 
	                        }
	                    }
	                }
	                if(workOrder.Tax_Code_3__c!=null)
	                {
	                    for(c2g__codaTaxRate__c taxRate : taxCodesById.get(workOrder.Tax_Code_3__c).c2g__TaxRates__r)
	                    {
	                        if(taxRate.c2g__StartDate__c <= workOrder.Completion_Date__c)
	                        {
	                             workOrder.Tax_Rate_3__c = taxRate.c2g__Rate__c;
	                             break; 
	                        }
	                    }
	                }
	            }
		    }
		}
    }	
    else if (Trigger.IsAfter)
    {
        // Trigger update on Work Order Line items if Customer Account or Completion Date has changed
        List<ID> modifiedAccountsOnWorkOrders = new List<ID>(); 
        for(integer idx = 0; idx<Trigger.new.size(); idx++)     
        {
            Work_Order__c newWorkOrder = Trigger.new[idx];
            Work_Order__c oldWorkOrder = Trigger.old[idx]; 
            if(newWorkOrder.Customer_Account__c != oldWorkOrder.Customer_Account__c ||
               newWorkOrder.Completion_Date__c != oldWorkOrder.Completion_Date__c)
                modifiedAccountsOnWorkOrders.add(newWorkOrder.Id);
        }
        for(Work_Order_Line_Item__c[] lines : [select Id from Work_Order_Line_Item__c where Work_Order__c in :modifiedAccountsOnWorkOrders])
            update lines; 
    }	
}