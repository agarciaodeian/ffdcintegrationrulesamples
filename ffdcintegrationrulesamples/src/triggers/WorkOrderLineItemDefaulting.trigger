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
trigger WorkOrderLineItemDefaulting on Work_Order_Line_Item__c (before insert, before update) 
{
    // Load Work Orders
    Map<ID, ID> workOrderIds = new Map<ID, ID>();
    for(Work_Order_Line_Item__c workOrderLineItem : Trigger.new)
        workOrderIds.put(workOrderLineItem.Work_Order__c, workOrderLineItem.Work_Order__c);
    List<Work_Order__c> workOrders = 
        [select Id, 
        	Customer_Account__c,
        	Completion_Date__c,
            Tax_Code_1__c, 
            Tax_Code_2__c, 
            Tax_Code_3__c, 
            Tax_Rate_1__c, 
            Tax_Rate_2__c, 
            Tax_Rate_3__c
            from Work_Order__c
            where Id in :workOrderIds.values()];
    Map<ID, Work_Order__c> workOrdersById = new Map<ID, Work_Order__c>();
    for(Work_Order__c workOrder : workOrders)
        workOrdersById.put(workOrder.Id, workOrder);
        
	// VAT
	if(FFUtil.isCurrentCompanyVAT())
	{
		// Load Accounts
		Map<ID, ID> accountIds = new Map<ID, ID>();
    	for(Work_Order__c workOrder : workOrders)
        	accountIds.put(workOrder.Customer_Account__c, workOrder.Customer_Account__c);
    	Map<ID, Account> accountById = new Map<ID, Account>();
	    List<Account> accounts = 
	        [select Id, c2g__CODAVATStatus__c, c2g__CODASalesTaxStatus__c, c2g__CODAOutputVATCode__c
	            from Account where Id in :accountIds.values()];
	    for(Account account : accounts)
	        accountById.put(account.Id, account);
	        
	    // Load Products	    
	    Map<ID, ID> productIds = new Map<ID, ID>();
	    for(Work_Order_Line_Item__c workOrderLineItem : Trigger.new)
	    	productIds.put(workOrderLineItem.Product__c, workOrderLineItem.Product__c);
    	Map<ID, Product2> productById = new Map<ID, Product2>();
	    List<Product2> products = 
	        [select Id, c2g__CODATaxCode__c 
	            from Product2 where Id in :productIds.values()];
	    for(Product2 product : products)
	        productById.put(product.Id, product);
	
		// Default tax code 1 on each lines
		Id defaultTaxCodeId = FFUtil.getDefaultCompanyTaxCode();
        Date minCompletionDate = null;
        Date maxCompletionDate = null;
		Map<ID, ID> taxCodeIds = new Map<ID, ID>();
	    for(Work_Order_Line_Item__c workOrderLineItem : Trigger.new)
	    {
	    	// Clear
	    	workOrderLineItem.Tax_Code_1__c = null;
	    	workOrderLineItem.Tax_Code_2__c = null;
	    	workOrderLineItem.Tax_Code_3__c = null;
	    	
	    	// Default tax code according to tax status on associated account
	    	Work_Order__c workOrder = workOrdersById.get(workOrderLineItem.Work_Order__c); 
	    	Account account = accountById.get(workOrder.Customer_Account__c);
	    	Product2 product = productById.get(workOrderLineItem.Product__c);
	    	if(account==null || product==null)
	    		continue;
	    	
	    	// Use Account for EC Registered and Export / Use Product for Home and EC Non-Registered
	    	if(account.c2g__CODAVATStatus__c == 'EC Registered' || account.c2g__CODAVATStatus__c == 'Export')
	    		workOrderLineItem.Tax_Code_1__c = account.c2g__CODAOutputVATCode__c;	    		
	    	else if(account.c2g__CODAVATStatus__c == 'Home' || account.c2g__CODAVATStatus__c == 'EC Non-Registered')
	    		workOrderLineItem.Tax_Code_1__c = product.c2g__CODATaxCode__c;
	    	if(workOrderLineItem.Tax_Code_1__c == null)
	    		workOrderLineItem.Tax_Code_1__c = defaultTaxCodeId;
	    	workOrderLineItem.Tax_Code_2__c = null;
	    	workOrderLineItem.Tax_Code_3__c = null;
	    		
			// Log Tax Code ID's used	    		
	    	taxCodeIds.put(workOrderLineItem.Tax_Code_1__c, workOrderLineItem.Tax_Code_1__c);
	    	
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
        for(Work_Order_Line_Item__c workOrderLineItem : Trigger.new)
        {
            // Default to zero 
            workOrderLineItem.Tax_Rate_1__c = 0;
            workOrderLineItem.Tax_Rate_2__c = 0;
            workOrderLineItem.Tax_Rate_3__c = 0;
            // Account? Or Tax Exempt Accounts?
            Work_Order__c workOrder = workOrdersById.get(workOrderLineItem.Work_Order__c);
            Account account = accountById.get(workOrder.Customer_Account__c);
            if(account==null || account.c2g__CODASalesTaxStatus__c == 'Exempt')
                continue;
            // Resolve rate according to completion date of work item               
            if(workOrderLineItem.Tax_Code_1__c!=null)
            {
                for(c2g__codaTaxRate__c taxRate : taxCodesById.get(workOrderLineItem.Tax_Code_1__c).c2g__TaxRates__r)
                {
                    if(taxRate.c2g__StartDate__c <= workOrder.Completion_Date__c)
                    {
                         workOrderLineItem.Tax_Rate_1__c = taxRate.c2g__Rate__c;
                         break; 
                    }
                }
            }
        }
	}
	// SUT
	else
	{        
	    // Sync up Tax Codes and Rates from Work Order onto lines
	    for(Work_Order_Line_Item__c workOrderLineItem : Trigger.new)
	    {
	        Work_Order__c workOrder = workOrdersById.get(workOrderLineItem.Work_Order__c);
	        workOrderLineItem.Tax_Code_1__c = workOrder.Tax_Code_1__c; 
	        workOrderLineItem.Tax_Code_2__c = workOrder.Tax_Code_2__c;
	        workOrderLineItem.Tax_Code_3__c = workOrder.Tax_Code_3__c;
	        workOrderLineItem.Tax_Rate_1__c = workOrder.Tax_Rate_1__c; 
	        workOrderLineItem.Tax_Rate_2__c = workOrder.Tax_Rate_2__c;
	        workOrderLineItem.Tax_Rate_3__c = workOrder.Tax_Rate_3__c;
	    }   
	}
}