*** Settings ***
Documentation       Producer main suite

Library             RPA.JSON
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Robocloud.Secrets
Library             String
Library             RPA.Outlook.Application
Library             RPA.Tables
Library             RPA.Robocorp.WorkItems


*** Variables ***
${Config1}


*** Tasks ***
Producer Bot Task
    TRY
        Get Data From Config1 File
        Testing
        ${inputData}=    Read Input File
        Upload Input in WorkItems    ${inputData}
    EXCEPT    AS    ${Exception}
        Log To Console    ${Exception}
        #Send Application Email    ${Config1}[AE]    ${Exception}
    END


*** Keywords ***
Get Data From Config1 File
    ${json}=    Load JSON from file    config.json
    Set Global Variable    ${Config1}    ${json}

Send Application Email
    [Arguments]    ${Subject}    ${Body}
    ${Body}=    Replace String    string=${Config1}[Body]    search_for=body    replace_with=${Body}
    Log To Console    data:-${Body}
    Send Email    recipients=${Config1}[accountName]    subject=${Subject}    body=${Body}

Read Input File
    Log To Console    headers:--${Config1}[headers][0][First Name]
    ${headers}=    Create List
    ...    ${Config1}[headers][0][First Name]
    ...    ${Config1}[headers][0][Last Name]
    ...    ${Config1}[headers][0][Company Name]
    ...    ${Config1}[headers][0][Role In Company]
    ...    ${Config1}[headers][0][Address]
    ...    ${Config1}[headers][0][E-Mail]
    ...    ${Config1}[headers][0][Phone Number]
    ${input}=    Read table from CSV    ${Config1}[Input_File_Path]    columns=${headers}
    FOR    ${element}    IN    @{input}
        Log To Console    ${element}
    END
    Filter Empty Rows    ${input}
    RETURN    ${input}

Upload Input in WorkItems
    [Arguments]    ${inputData}

    FOR    ${row}    IN    @{inputData}
        ${Dict}=    Create Dictionary    inputData=${row}
        Create Output Work Item    ${Dict}
        Save Work Item
    END

Testing
    Attach Chrome Browser    9222
    Go To    https://www.rpahackathon.co.uk/l1
    Click Link    xpath://*[@id="form-home"]/div[3]/div[2]/a    #Download CSV File
    Submit Form    #Click on Start
    Page Should Contain Element    id:timer    Step1 is not opened
