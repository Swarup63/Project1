*** Settings ***
Suite Setup       Run Keywords    Set Library Search Order    CustomDB    DatabaseLibrary    CustomSelenium2Library
...               AND    Connect With DB
Suite Teardown    Run Keywords    Disconnect with DB
...               AND    Close All Open Browsers
...               AND    Clean Up Context
...               AND    Close All Connections
Test Setup        Run Keywords    Open SSH Connection    AND    Login Web App    ${CX_URL}    ${CX_USER}    ${CX_PASSWORD}    ${BROWSER}
Test Teardown     Run Keywords     Web Teardown    AND    Clean Up Context
Library           ../../../../keywords/webService/ContextHandler.py
Library           ../../../../keywords/common/customDB/CustomDB.py
Resource          ../../../../keywords/batch/Common.txt
Resource          ../../../../keywords/common/Assertions.txt
Resource          ../../../../keywords/common/Common.txt
Resource          ../../../../keywords/webClient/CX/contract.txt
Resource          ../../../../keywords/webClient/CX/customer.txt
Resource          ../../../../keywords/webClient/Commom.txt
Resource          ../../../../keywords/webService/soapService.txt
Resource          ../../soap/requestLib/requestLib.txt
Resource          ../../../../keywords/webClient/CustomSelenium2Library.txt
Variables         ../../../variables.py

*** Test Cases ***
processUDRAndGenerateInvoiceBSCSContract
    [Documentation]    This test verifies that it is possible to create a BSCS contract with base product, process UDR, bill the customer and display it in CX.
    [Tags]    CIL_6    CIL_7    lsvCritical    licenseON=LHS_BSCS_FS_GENERAL
    #    Create Customer and Contract
    ${internalID}    Generate Random Number    3
    Add To Context    loginUserHolder    EOC
    Add To Context    loginPasswordHolder    EOC
    ${productOfferingId}    Add To Context    productOfferingIdHolder    BBaseSimple
    ${cfssIdHolder}    Add To Context    cfssIdHolder    BVOICE1
    #testData createCustomerSearchResources
    ${csIdPub}    Create Basic Customer
    ${csIdPubHolder}    Add To Context    csIdPubHolder    ${csIdPub}
    ${cocode}    Create Contract    ${productOfferingId}    ${csIdPubHolder}    ${cfssIdHolder}
    ${cocodeHolder}    Add To Context    cocodeHolder    ${cocode}
    ${productOfferingName}    Add To Context    productOfferingNameHolder    BSCS Base PO Simple
    ${productId}    Get ProductID    ${cocode}
    #    Get Customer from DB
    ${rset}    Query    SELECT DISTINCT C.CUSTOMER_ID, C.CO_CODE, D.DN_NUM, PRT.PORT_NUM IMSI, STM.SM_SERIALNUM IMEI FROM PR_SERV_SPCODE_HIST SPHIST, CONTR_SERVICES_CAP CS, CONTRACT_ALL C, DIRECTORY_NUMBER D, PORT PRT, CONTR_DEVICES CDV, STORAGE_MEDIUM STM WHERE SPHIST.PRODUCT_ID = '${productId}' AND CS.CO_ID = SPHIST.CO_ID AND C.CO_ID = CS.CO_ID AND D.DN_ID = CS.DN_ID AND CDV.CO_ID = C.CO_ID AND PRT.PORT_ID = CDV.PORT_ID AND STM.SM_ID = PRT.SM_ID AND STM.SM_ID = PRT.SM_ID
    ${customerId}    Set Variable    ${rset[0][0]}
    ${coCode}    Set Variable    ${rset[0][1]}
    ${dirNum}    Set Variable    ${rset[0][2]}
    ${imsi}    Set Variable    ${rset[0][3]}
    ${imei}    Set Variable    ${rset[0][4]}
    Active Contract    ${coCode}
    #    Process UDR
    ${params}    Set Variable    ${dirNum} ${imsi} ${imei} ${productOfferingId} ${productId} ${cfssIdHolder} ${customerId}
    Go to test path
    Send SSH Command    bash -x ./buc2_slice3_process_udr.sh ${params}
    Validate AutReport
    #    Validate CX Contract
    Search Contract    ${coCode}
    ${productOfferingName}    Set Variable    BSCS Base PO Simple
    ${cfsSpecNameCfss}    Set Variable    BVOICE1
    Element Should Be Visible    xpath=//*[@id='SERVICES_TABLE']//span[normalize-space(text())='${productOfferingName}']
    Element Should Be Visible    xpath=//*[@id='SERVICES_TABLE']//span[normalize-space(text())='${productId}']
    Expand Service on Tree    ${productOfferingName}
    Element Should Be Visible    xpath=//*[@id='SERVICES_TABLE']//a[normalize-space(text())='${productOfferingName}']
    Go to Contract Billing Usage Events
    Element Should Be Visible    xpath=//*[@id='Event_TableModel']//td[normalize-space(text())='${productOfferingName}']
    Element Should Be Visible    xpath=//*[@id='Event_TableModel']//td[normalize-space(text())='${cfsSpecNameCfss}']
    Element Should Be Visible    xpath=//*[@id='Event_TableModel']//td[normalize-space(text())='${productId}']
