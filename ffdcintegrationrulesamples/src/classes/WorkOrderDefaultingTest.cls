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
private class WorkOrderDefaultingTest 
{
	// Test company names
	private static String VAT_COMPANY_NAME = 'MerlinTech Ltd (Test)';
	private static String SUT_COMPANY_NAME = 'MerlinTech, inc (Test)';
	
	// Test tax code names
	private static String TAX_CODE_1_NAME = 'TAXCODE1'; 
	private static String TAX_CODE_2_NAME = 'TAXCODE2';
	private static String TAX_CODE_3_NAME = 'TAXCODE3';
	
	// Test product names
	private static String PRODUCT_1_NAME = 'Test Product 1';
	private static String PRODUCT_2_NAME = 'Test Product 2';
	
	/**
	 * Create empty or potentially invalid work orders, ensure it does not error
	 **/
	public static testmethod void robustnessAllNulls()
	{	
		// Test in both VAT and SUT modes
		for(c2g__codaCompany__c company : createTestCompanies().values())
		{
			// Set current company context 
			FFUtil.setTestCompany(company);
			// Create empty / invalid work orders
			Work_Order__c workOrder = new Work_Order__c();
			insert workOrder;
			Work_Order_Line_Item__c workOrderLineItem = new Work_Order_Line_Item__c();
			workOrderLineItem.Work_Order__c = workOrder.Id;
			insert workOrderLineItem;
		} 				
	}

	/**
	 * Create empty or potentially invalid work orders, ensure it does not error
	 **/
	public static testmethod void robustnessCompletionOnly()
	{	
		// Test in both VAT and SUT modes
		for(c2g__codaCompany__c company : createTestCompanies().values())
		{
			// Set current company context 
			FFUtil.setTestCompany(company);
			// Create empty / invalid work orders
			Work_Order__c workOrder = new Work_Order__c();
			workOrder.Completion_Date__c = System.now().date();
			insert workOrder;
			Work_Order_Line_Item__c workOrderLineItem = new Work_Order_Line_Item__c();
			workOrderLineItem.Work_Order__c = workOrder.Id;
			insert workOrderLineItem;
		} 				
	}

	/**
	 * Create empty or potentially invalid work orders, ensure it does not error
	 **/
	public static testmethod void robustnessAccountOnly()
	{	
		// Create Account
		Account account = new Account();
		account.Name = 'Test Account';
		insert account;
		
		// Test in both VAT and SUT modes
		for(c2g__codaCompany__c company : createTestCompanies().values())
		{
			// Set current company context 
			FFUtil.setTestCompany(company);
			// Create empty / invalid work orders
			Work_Order__c workOrder = new Work_Order__c();
			workOrder.Customer_Account__c = account.Id;
			insert workOrder;
			Work_Order_Line_Item__c workOrderLineItem = new Work_Order_Line_Item__c();
			workOrderLineItem.Work_Order__c = workOrder.Id;
			insert workOrderLineItem;
		} 							
	}
	
	/**
	 * Create Work Orders in a VAT company context (Taxable Home Account)
	 **/
	public static testmethod void testVatWorkOrdersTaxableHomeAccount()
	{
		// Set VAT current company context 
		FFUtil.setTestCompany(createTestCompanies().get(VAT_COMPANY_NAME));
		System.assert(FFUtil.isCurrentCompanyVAT() && FFUtil.isCurrentCompanySalesAndUse()==false);			
		
		// Create test Work Order and test defaulted tax codes and rates
		Work_Order__c workOrder = createWorkOrder('Taxable', 'Home');
		System.assertEquals(null, workOrder.Tax_Code_1__c);
		System.assertEquals(0, workOrder.Tax_Rate_1__c);
		System.assertEquals(null, workOrder.Tax_Code_2__c);
		System.assertEquals(0, workOrder.Tax_Rate_2__c);
		System.assertEquals(null, workOrder.Tax_Code_3__c);
		System.assertEquals(0, workOrder.Tax_Rate_3__c);
		for(Work_Order_Line_Item__c lineItem : workOrder.Work_Order_Line_Items__r)
		{
			if(lineItem.Product__r.Name.equals(PRODUCT_1_NAME))
			{
				System.assertEquals(TAX_CODE_2_NAME, lineItem.Tax_Code_1__r.Name);
				System.assertEquals(20, lineItem.Tax_Rate_1__c);
			}
			else if(lineItem.Product__r.Name.equals(PRODUCT_1_NAME))
			{
				System.assertEquals(TAX_CODE_3_NAME, lineItem.Tax_Code_1__r.Name);
				System.assertEquals(30, lineItem.Tax_Rate_1__c);
			}
			System.assertEquals(null, workOrder.Tax_Code_2__c);
			System.assertEquals(0, lineItem.Tax_Rate_2__c);
			System.assertEquals(null, workOrder.Tax_Code_3__c);
			System.assertEquals(0, lineItem.Tax_Rate_3__c);			
		}
	}

	/**
	 * Create Work Orders in a VAT company context (Taxable Export Account)
	 **/
	public static testmethod void testVatWorkOrdersTaxableExportAccount()
	{
		// Set VAT current company context 
		FFUtil.setTestCompany(createTestCompanies().get(VAT_COMPANY_NAME));
		System.assert(FFUtil.isCurrentCompanyVAT() && FFUtil.isCurrentCompanySalesAndUse()==false);			
		
		// Create test Work Order and test defaulted tax codes and rates
		Work_Order__c workOrder = createWorkOrder('Taxable', 'Export');
		System.assertEquals(null, workOrder.Tax_Code_1__c);
		System.assertEquals(0, workOrder.Tax_Rate_1__c);
		System.assertEquals(null, workOrder.Tax_Code_2__c);
		System.assertEquals(0, workOrder.Tax_Rate_2__c);
		System.assertEquals(null, workOrder.Tax_Code_3__c);
		System.assertEquals(0, workOrder.Tax_Rate_3__c);
		for(Work_Order_Line_Item__c lineItem : workOrder.Work_Order_Line_Items__r)
		{
			System.assertEquals(TAX_CODE_1_NAME, lineItem.Tax_Code_1__r.Name);
			System.assertEquals(10, lineItem.Tax_Rate_1__c);
			System.assertEquals(null, workOrder.Tax_Code_2__c);
			System.assertEquals(0, lineItem.Tax_Rate_2__c);
			System.assertEquals(null, workOrder.Tax_Code_3__c);
			System.assertEquals(0, lineItem.Tax_Rate_3__c);			
		}
	}

	/**
	 * Create Work Orders in a VAT company context (Exempt Home Account)
	 **/
	public static testmethod void testVatWorkOrdersExemptHomeAccount()
	{
		// Set VAT current company context 
		FFUtil.setTestCompany(createTestCompanies().get(VAT_COMPANY_NAME));
		System.assert(FFUtil.isCurrentCompanyVAT() && FFUtil.isCurrentCompanySalesAndUse()==false);			
		
		// Create test Work Order and test defaulted tax codes and rates
		Work_Order__c workOrder = createWorkOrder('Exempt', 'Home');
		System.assertEquals(null, workOrder.Tax_Code_1__c);
		System.assertEquals(0, workOrder.Tax_Rate_1__c);
		System.assertEquals(null, workOrder.Tax_Code_2__c);
		System.assertEquals(0, workOrder.Tax_Rate_2__c);
		System.assertEquals(null, workOrder.Tax_Code_3__c);
		System.assertEquals(0, workOrder.Tax_Rate_3__c);
		for(Work_Order_Line_Item__c lineItem : workOrder.Work_Order_Line_Items__r)
		{
			if(lineItem.Product__r.Name.equals(PRODUCT_1_NAME))
			{
				System.assertEquals(TAX_CODE_2_NAME, lineItem.Tax_Code_1__r.Name);
				System.assertEquals(0, lineItem.Tax_Rate_1__c);
			}
			else if(lineItem.Product__r.Name.equals(PRODUCT_1_NAME))
			{
				System.assertEquals(TAX_CODE_3_NAME, lineItem.Tax_Code_1__r.Name);
				System.assertEquals(0, lineItem.Tax_Rate_1__c);
			}
			System.assertEquals(null, workOrder.Tax_Code_2__c);
			System.assertEquals(0, lineItem.Tax_Rate_2__c);
			System.assertEquals(null, workOrder.Tax_Code_3__c);
			System.assertEquals(0, lineItem.Tax_Rate_3__c);			
		}
	}

	/**
	 * Create Work Orders in a VAT company context (Exempt Export Account)
	 **/
	public static testmethod void testVatWorkOrdersExemptExportAccount()
	{
		// Set VAT current company context 
		FFUtil.setTestCompany(createTestCompanies().get(VAT_COMPANY_NAME));
		System.assert(FFUtil.isCurrentCompanyVAT() && FFUtil.isCurrentCompanySalesAndUse()==false);			
		
		// Create test Work Order and test defaulted tax codes and rates
		Work_Order__c workOrder = createWorkOrder('Exempt', 'Export');
		System.assertEquals(null, workOrder.Tax_Code_1__c);
		System.assertEquals(0, workOrder.Tax_Rate_1__c);
		System.assertEquals(null, workOrder.Tax_Code_2__c);
		System.assertEquals(0, workOrder.Tax_Rate_2__c);
		System.assertEquals(null, workOrder.Tax_Code_3__c);
		System.assertEquals(0, workOrder.Tax_Rate_3__c);
		for(Work_Order_Line_Item__c lineItem : workOrder.Work_Order_Line_Items__r)
		{
			System.assertEquals(TAX_CODE_1_NAME, lineItem.Tax_Code_1__r.Name);
			System.assertEquals(0, lineItem.Tax_Rate_1__c);
			System.assertEquals(null, workOrder.Tax_Code_2__c);
			System.assertEquals(0, lineItem.Tax_Rate_2__c);
			System.assertEquals(null, workOrder.Tax_Code_3__c);
			System.assertEquals(0, lineItem.Tax_Rate_3__c);			
		}
	}
	
	/**
	 * Create Work Orders in a SUT company context (Taxable account)
	 **/
	public static testmethod void testSutWorkOrdersTaxableAccount()
	{
		// Set SUT current company context
		FFUtil.setTestCompany(createTestCompanies().get(SUT_COMPANY_NAME));
		System.assert(FFUtil.isCurrentCompanySalesAndUse() && FFUtil.isCurrentCompanyVAT()==false);
		
		// Create test Work Order and test defaulted tax codes and rates
		Work_Order__c workOrder = createWorkOrder('Taxable', 'Home');
		System.assertEquals(TAX_CODE_1_NAME, workOrder.Tax_Code_1__r.Name);
		System.assertEquals(10, workOrder.Tax_Rate_1__c);
		System.assertEquals(TAX_CODE_2_NAME, workOrder.Tax_Code_2__r.Name);
		System.assertEquals(20, workOrder.Tax_Rate_2__c);
		System.assertEquals(TAX_CODE_3_NAME, workOrder.Tax_Code_3__r.Name);
		System.assertEquals(30, workOrder.Tax_Rate_3__c);
		for(Work_Order_Line_Item__c lineItem : workOrder.Work_Order_Line_Items__r)
		{
			System.assertEquals(TAX_CODE_1_NAME, lineItem.Tax_Code_1__r.Name);
			System.assertEquals(10, lineItem.Tax_Rate_1__c);
			System.assertEquals(TAX_CODE_2_NAME, lineItem.Tax_Code_2__r.Name);
			System.assertEquals(20, lineItem.Tax_Rate_2__c);
			System.assertEquals(TAX_CODE_3_NAME, lineItem.Tax_Code_3__r.Name);
			System.assertEquals(30, lineItem.Tax_Rate_3__c);			
		}
	}

	/**
	 * Create Work Orders in a SUT company context (Exempt account)
	 **/
	public static testmethod void testSutWorkOrdersExemptAccount()
	{
		// Set SUT current company context
		FFUtil.setTestCompany(createTestCompanies().get(SUT_COMPANY_NAME));
		System.assert(FFUtil.isCurrentCompanySalesAndUse() && FFUtil.isCurrentCompanyVAT()==false);
		
		// Create test Work Order and test defaulted tax codes and rates
		Work_Order__c workOrder = createWorkOrder('Exempt', 'Home');
		System.assertEquals(TAX_CODE_1_NAME, workOrder.Tax_Code_1__r.Name);
		System.assertEquals(0, workOrder.Tax_Rate_1__c);
		System.assertEquals(TAX_CODE_2_NAME, workOrder.Tax_Code_2__r.Name);
		System.assertEquals(0, workOrder.Tax_Rate_2__c);
		System.assertEquals(TAX_CODE_3_NAME, workOrder.Tax_Code_3__r.Name);
		System.assertEquals(0, workOrder.Tax_Rate_3__c);
		for(Work_Order_Line_Item__c lineItem : workOrder.Work_Order_Line_Items__r)
		{
			System.assertEquals(TAX_CODE_1_NAME, lineItem.Tax_Code_1__r.Name);
			System.assertEquals(0, lineItem.Tax_Rate_1__c);
			System.assertEquals(TAX_CODE_2_NAME, lineItem.Tax_Code_2__r.Name);
			System.assertEquals(0, lineItem.Tax_Rate_2__c);
			System.assertEquals(TAX_CODE_3_NAME, lineItem.Tax_Code_3__r.Name);
			System.assertEquals(0, lineItem.Tax_Rate_3__c);			
		}
	}
	
	/**
	 * Create Work Order with an Account with Base Date specified
	 **/
	public static testmethod void testAccountBasedDueDate()
	{
		// Set VAT current company context 
		FFUtil.setTestCompany(createTestCompanies().get(VAT_COMPANY_NAME));
		System.assert(FFUtil.isCurrentCompanyVAT() && FFUtil.isCurrentCompanySalesAndUse()==false);			
		
		// Create test Work Order and test defaulted Due Date (from Account)
		Work_Order__c workOrder = createWorkOrder('Exempt', 'Home', true, Date.newInstance(2010, 1, 1));
		System.assertEquals(Date.newInstance(2010, 1, 16), workOrder.Due_Date__c);		
	}
	
	/**
	 * Create Work Order with an Account without Base Date specified and thus inherit from company
	 **/
	public static testmethod void testCompanyBasedDueDate()
	{
		// Set VAT current company context 
		FFUtil.setTestCompany(createTestCompanies().get(VAT_COMPANY_NAME));
		System.assert(FFUtil.isCurrentCompanyVAT() && FFUtil.isCurrentCompanySalesAndUse()==false);			
		
		// Create test Work Order and test defaulted Due Date (from Company)
		Work_Order__c workOrder = createWorkOrder('Exempt', 'Home', false, Date.newInstance(2010, 1, 1));
		System.assertEquals(Date.newInstance(2010, 1, 31), workOrder.Due_Date__c);		
		
	}
	
	/**
	 * Create Work Order and ensure Invoice currency defaulted correctly 
	 **/
	public static testmethod void testInvoiceCurrencyDefault()
	{
		// Set VAT current company context 
		FFUtil.setTestCompany(createTestCompanies().get(VAT_COMPANY_NAME));
		System.assert(FFUtil.isCurrentCompanyVAT() && FFUtil.isCurrentCompanySalesAndUse()==false);			
		
		// Create test Work Order and test defaulted Currency
		Work_Order__c workOrder = createWorkOrder('Exempt', 'Home', false, Date.newInstance(2010, 1, 1));
		System.assertEquals(workOrder.Invoice_Currency__r.Name, 'USD');		
	}
	
	/**
	 * Create Work Order and ensure Period defaulted correctly
	 **/
	public static testmethod void testDefaultPeriod()
	{
		// Set VAT current company context 
		FFUtil.setTestCompany(createTestCompanies().get(VAT_COMPANY_NAME));
		System.assert(FFUtil.isCurrentCompanyVAT() && FFUtil.isCurrentCompanySalesAndUse()==false);			
	
		/**
	     * TODO: This test has been removed due to issues setting up Year, see createTestCompanies	     
		// Create test Work Order and test defaulted Period
		Work_Order__c workOrder = createWorkOrder('Exempt', 'Home', false, Date.newInstance(2012, 1, 1));
		System.assertEquals(workOrder.Period__r.Name, '2012/001');
		 **/				
	}
	
	/**
	 * Creates a test work order including supporting test data (account, product, tax code and tax rates)
	 **/
	private static Work_Order__c createWorkOrder(String salesTaxStatus, String vatStatus)
	{
		return createWorkOrder(salesTaxStatus, vatStatus, false, null);
	}
		
	/**
	 * Creates a test work order including supporting test data (account, product, tax code and tax rates)
	 **/
	private static Work_Order__c createWorkOrder(String salesTaxStatus, String vatStatus, Boolean accountBaseDate, Date invoiceDate)
	{
		// Create Tax Codes
		Map<String, c2g__codaTaxCode__c> taxCodes = createTestTaxCodes();
		
		// Create Account Currency
		c2g__codaAccountingCurrency__c usdCurrency = new c2g__codaAccountingCurrency__c();
		usdCurrency.Name = 'USD';
		usdCurrency.c2g__DecimalPlaces__c = 2;
		usdCurrency.CurrencyIsoCode = 'USD';
		insert usdCurrency;
		
		// Create Account
		Account account = new Account();
		account.Name = 'Test Account';
		account.CurrencyIsoCode = 'USD';
		account.c2g__CODASalesTaxStatus__c = salesTaxStatus;
		account.c2g__CODATaxCode1__c = taxCodes.get(TAX_CODE_1_NAME).Id;
		account.c2g__CODATaxCode2__c = taxCodes.get(TAX_CODE_2_NAME).Id;
		account.c2g__CODATaxCode3__c = taxCodes.get(TAX_CODE_3_NAME).Id;
		account.c2g__CODAVATStatus__c = vatStatus;
		account.c2g__CODAOutputVATCode__c = taxCodes.get(TAX_CODE_1_NAME).Id;
		if(accountBaseDate)
		{
			account.c2g__CODABaseDate1__c = FFUtil.BASE_DATE_INVOICE_DATE;
			account.c2g__CODADaysOffset1__c = 15;					
		}
		insert account;
		
		// Create Products
		List<Product2> products = new List<Product2>();
		Product2 product1 = new Product2();
		product1.Name = PRODUCT_1_NAME;
		product1.c2g__CODATaxCode__c = taxCodes.get(TAX_CODE_2_NAME).Id;
		products.add(product1);
		Product2 product2 = new Product2();
		product2.Name = PRODUCT_2_NAME;
		product2.c2g__CODATaxCode__c = taxCodes.get(TAX_CODE_3_NAME).Id;
		products.add(product2);
		insert products;
		
		// Create Work Order
		Work_Order__c workOrder = new Work_Order__c();
		workOrder.Completion_Date__c = System.now().date();
		workOrder.Consultant__c = 'Lee Gray';
		workOrder.Customer_Account__c = account.Id;
		workOrder.Customer_Reference__c = 'CUSTREF#1';
		workOrder.Date__c = System.now().date();
		workOrder.Invoiced__c = false;
		workOrder.Sales_Invoice_Number__c = null;
		workOrder.Status__c = 'Open';
		workOrder.Invoice_Date__c = invoiceDate;
		insert workOrder;
		
		// Create Work Order Line Item
		List<Work_Order_Line_Item__c> workOrderLineItems = new List<Work_Order_Line_Item__c>(); 
		Work_Order_Line_Item__c workOrderLineItem1 = new Work_Order_Line_Item__c();
		workOrderLineItem1.Work_Order__c = workOrder.Id;
		workOrderLineItem1.Hourly_Rate__c = 15.5;
		workOrderLineItem1.Hours_Charged__c = 8;
		workOrderLineItem1.Product__c = product1.Id;
		workOrderLineItems.add(workOrderLineItem1);
		Work_Order_Line_Item__c workOrderLineItem2 = new Work_Order_Line_Item__c();
		workOrderLineItem2.Work_Order__c = workOrder.Id;
		workOrderLineItem2.Hourly_Rate__c = 2.5;
		workOrderLineItem2.Hours_Charged__c = 24;
		workOrderLineItem2.Product__c = product2.Id;
		workOrderLineItems.add(workOrderLineItem2);
		insert workOrderLineItems;

		// Read record back to inherit defaults from triggers
		Work_Order__c readWorkOrder = 
			[select 
				w.Tax_Rate_3__c, 
				w.Tax_Rate_2__c, 
				w.Tax_Rate_1__c, 
				w.Tax_Code_3__r.Name, 
				w.Tax_Code_3__c, 
				w.Tax_Code_2__r.Name, 
				w.Tax_Code_2__c, 
				w.Tax_Code_1__r.Name, 
				w.Tax_Code_1__c, w.Name,
				w.Due_Date__c,
				w.Invoice_Date__c,
				w.Period__c,
				w.Period__r.Name,
				w.Invoice_Currency__c,
				w.Invoice_Currency__r.Name,
				w.Id, 
					(Select 
						Tax_Code_1__c, 
						Tax_Code_1__r.Name,
						Tax_Code_2__c, 
						Tax_Code_2__r.Name,						
						Tax_Code_3__c, 
						Tax_Code_3__r.Name,						
						Tax_Rate_1__c, 
						Tax_Rate_2__c, 
						Tax_Rate_3__c,
						Product__c,
						Product__r.Name 
						From Work_Order_Line_Items__r) 
					From Work_Order__c w where Id = :workOrder.Id];		
		return readWorkOrder;
	}
			
	/**
	 * Create som etest tax codes and rates
	 **/
	private static Map<String, c2g__codaTaxCode__c> createTestTaxCodes()
	{
		// Create General Ledger Account
		c2g__codaGeneralLedgerAccount__c gla = new c2g__codaGeneralLedgerAccount__c();
		gla.Name = 'Sales Tax';
		gla.c2g__Type__c = 'Balance Sheet';
		gla.c2g__ReportingCode__c = 'SALESTAX';
		insert gla;
		 
		// Create Tax Codes 
		List<c2g__codaTaxCode__c> taxCodes = new List<c2g__codaTaxCode__c>();
		c2g__codaTaxCode__c taxCode1 = new c2g__codaTaxCode__c();
		taxCode1.Name = TAX_CODE_1_NAME;
		taxCode1.c2g__GeneralLedgerAccount__c = gla.Id;
		taxCode1.c2g__Description__c = 'Tax Code Descripton ' + TAX_CODE_1_NAME; 
		taxCode1.c2g__TaxGroup__c = 'CA';
		taxCodes.add(taxCode1);
		c2g__codaTaxCode__c taxCode2 = new c2g__codaTaxCode__c();
		taxCode2.Name = TAX_CODE_2_NAME;
		taxCode2.c2g__GeneralLedgerAccount__c = gla.Id;
		taxCode2.c2g__Description__c = 'Tax Code Descripton ' + TAX_CODE_2_NAME; 
		taxCode2.c2g__TaxGroup__c = 'CA';
		taxCodes.add(taxCode2);
		c2g__codaTaxCode__c taxCode3 = new c2g__codaTaxCode__c();
		taxCode3.Name = TAX_CODE_3_NAME;
		taxCode3.c2g__GeneralLedgerAccount__c = gla.Id;
		taxCode3.c2g__Description__c = 'Tax Code Descripton ' + TAX_CODE_3_NAME; 
		taxCode3.c2g__TaxGroup__c = 'CA';
		taxCodes.add(taxCode3);
		insert taxCodes;
		
		// Create Tax Rates
		List<c2g__codaTaxRate__c> taxRates = new List<c2g__codaTaxRate__c>();
		c2g__codaTaxRate__c taxRate1 = new c2g__codaTaxRate__c();
		taxRate1.c2g__Rate__c = 10;
		taxRate1.c2g__StartDate__c = System.now().addMonths(-1).date();
		taxRate1.c2g__TaxCode__c = taxCode1.Id;
		taxRates.add(taxRate1); 
		c2g__codaTaxRate__c taxRate2 = new c2g__codaTaxRate__c();
		taxRate2.c2g__Rate__c = 20;
		taxRate2.c2g__StartDate__c = System.now().addMonths(-1).date();
		taxRate2.c2g__TaxCode__c = taxCode2.Id;
		taxRates.add(taxRate2); 
		c2g__codaTaxRate__c taxRate3 = new c2g__codaTaxRate__c();
		taxRate3.c2g__Rate__c = 30;
		taxRate3.c2g__StartDate__c = System.now().addMonths(-1).date();
		taxRate3.c2g__TaxCode__c = taxCode3.Id;
		taxRates.add(taxRate3); 
		insert taxRates;  
		
		// Return Tax Codes
		Map<String, c2g__codaTaxCode__c> taxCodesByName = new Map<String, c2g__codaTaxCode__c>();
		taxCodesByName.put(TAX_CODE_1_NAME, taxCode1); 
		taxCodesByName.put(TAX_CODE_2_NAME, taxCode2);
		taxCodesByName.put(TAX_CODE_3_NAME, taxCode3);
		return taxCodesByName;
	}
	
	/**
	 * Create some test companies
	 **/
	private static Map<String, c2g__codaCompany__c> createTestCompanies()
	{
		// Create VAT company
		RecordType vatRecordType = [select Id, Name from RecordType where Name = 'VAT'];		
		c2g__codaCompany__c vatCompany = new c2g__codaCompany__c();
		vatCompany.RecordTypeId = vatRecordType.Id; 
		vatCompany.Name = VAT_COMPANY_NAME;
		vatCompany.c2g__ECCountryCode__c = 'GB';
		vatCompany.c2g__VATRegistrationNumber__c = 'VATREG01';
		vatCompany.c2g__CODABaseDate1__c = FFUtil.BASE_DATE_INVOICE_DATE;
		vatCompany.c2g__CODADaysOffset1__c = 30;		
		insert vatCompany;

		/** 
		 * TODO: This causes issues as the test is not isolated from company config of the user running the test
		 *         and thus becomes dependent on existing org data and current company assignment rules	
			// Create Year
			c2g__codaYear__c vatYear = new c2g__codaYear__c();
			vatYear.Name = '2012';
			vatYear.c2g__StartDate__c = Date.newInstance(2012, 1, 1);
			vatYear.c2g__EndDate__c = Date.newInstance(2012, 12, 31);
			vatYear.c2g__PeriodCalculationBasis__c = 'Month End';
			vatYear.c2g__NumberOfPeriods__c = 12;
			vatYear.c2g__OwnerCompany__c = vatCompany.Id;
			insert vatYear;
		**/
		
		// Create SUT company
		RecordType sutRecordType = [select Id, Name from RecordType where Name = 'SUT'];
		c2g__codaCompany__c sutCompany = new c2g__codaCompany__c();
		sutCompany.RecordTypeId = sutRecordType.Id; 
		sutCompany.Name = SUT_COMPANY_NAME;		 
		sutCompany.c2g__CODABaseDate1__c = FFUtil.BASE_DATE_INVOICE_DATE;
		sutCompany.c2g__CODADaysOffset1__c = 30;		
		insert sutCompany;
		
		// Query company records back		 
		List<c2g__codaCompany__c> companies =
			[select Id, Name, RecordType.Name, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c from c2g__codaCompany__c where Id = :sutCompany.Id or Id = :vatCompany.Id];
		Map<String, c2g__codaCompany__c> companiesMap = new Map<String, c2g__codaCompany__c>();
		for(c2g__codaCompany__c company : companies)
			companiesMap.put(company.Name, company);
		return companiesMap; 		 
	}
}