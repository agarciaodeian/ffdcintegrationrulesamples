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
trigger DirectReceiptDefaulting on Direct_Receipt__c (before insert, before update) {
	
	if(Trigger.isBefore)
    {
        if(Trigger.isUpdate || Trigger.isInsert)
        {
        	// Load Accounts and Bank Accounts
            Map<ID, ID> accountIds = new Map<ID, ID>();
            Map<ID, ID> bankAccountIds = new Map<ID, ID>();
            for(Direct_Receipt__c directReceipt : Trigger.new)
            {
            	if(directReceipt.Customer_Account__c!=null)
                    accountIds.put(directReceipt.Customer_Account__c, directReceipt.Customer_Account__c);
                
                if(directReceipt.Bank_Account__c!=null)
                    bankAccountIds.put(directReceipt.Bank_Account__c, directReceipt.Bank_Account__c);    
            
            }
                
            List<ID> accountIdsList = accountIds.values();
            String accountSOQL =  // Avoid multi-currency dependency on package via dynamic SOQL 
            	'select Id, c2g__CODAPaymentMethod__c, CurrencyIsoCode from Account where Id in :accountIdsList';
            List<Account> accounts = Database.query(
            	FFUtil.isMultiCurrencyOrganization() ? accountSOQL : accountSOQL.replace(', CurrencyIsoCode', ''));
            Map<ID, Account> accountById = new Map<ID, Account>();
            for(Account account : accounts)
                accountById.put(account.Id, account);
                
           List<c2g__CODABankAccount__c> bankAccounts = 
                [select Id, c2g__BankAccountCurrency__c  from c2g__CODABankAccount__c where Id in :bankAccountIds.values()];
            Map<ID, c2g__CODABankAccount__c> bankAccountById = new Map<ID, c2g__CODABankAccount__c>();
           for(c2g__CODABankAccount__c bankAccount : bankAccounts)
                bankAccountById.put(bankAccount.Id, bankAccount); 
           
            List<c2g__CODAAccountingCurrency__c> accountingCurrencies = 
                [select Id, Name  from c2g__CODAAccountingCurrency__c];
            Map<ID, c2g__CODAAccountingCurrency__c> accountingCurrencyById = new Map<ID, c2g__CODAAccountingCurrency__c>();
           for(c2g__CODAAccountingCurrency__c accountingCurrency : accountingCurrencies)
                accountingCurrencyById.put(accountingCurrency.Id, accountingCurrency);    
                    
        	
        	for(Direct_Receipt__c directReceipt : Trigger.new)
            {
            	if(directReceipt.Bank_Account__c != null)
            	{
            		c2g__CODABankAccount__c bankAccount = bankAccountById.get(directReceipt.Bank_Account__c); 	
            		directReceipt.Receipt_Currency__c = accountingCurrencyById.get(bankAccount.c2g__BankAccountCurrency__c).Name;	
            	}
            	
            	if(directReceipt.Customer_Account__c != null)
            	{
            		Account account = accountById.get(directReceipt.Customer_Account__c);
            		directReceipt.Account_Payment_Method__c = account.c2g__CODAPaymentMethod__c;
            		directReceipt.Payment_Currency__c = FFUtil.getAccountCurrencyIsoCode(account);
            	}
            }
        }
    }
}