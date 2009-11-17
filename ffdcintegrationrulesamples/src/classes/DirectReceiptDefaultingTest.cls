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

@IsTest
private class DirectReceiptDefaultingTest 
{
	public static testmethod void testDefaults()
	{
		// TODO: Issue creating an Account Currency in test context without a current company.
		/*
		// Create Account
		Account account = new Account();
		account.Name = 'Test Account';
		account.c2g__CODAPaymentMethod__c = 'Paper';
		account.CurrencyIsoCode = 'USD';
		insert account;
		
		// Create Accounting Currency
		c2g__CODAAccountingCurrency__c accountingCurrency = new c2g__CODAAccountingCurrency__c();
		accountingCurrency.Name = 'USD';
		insert accountingCurrency;
		
		// Create Bank Account
		c2g__CODABankAccount__c bankAccount = new c2g__CODABankAccount__c();
		bankAccount.Name = 'Test Bank Account';
		bankAccount.c2g__BankAccountCurrency__c = accountingCurrency.Id;
		insert bankAccount;
		*/
		
		// Insert a Direct Receipt		
		Direct_Receipt__c directReceipt = new Direct_Receipt__c();
		insert directReceipt;
	}
}