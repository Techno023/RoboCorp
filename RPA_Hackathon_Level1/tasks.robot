*** Settings ***
Documentation       Cunsumer main suite

Library             RPA.JSON
Library             RPA.Browser.Selenium    # auto_close=${FALSE}
Library             RPA.Robocorp.Vault
Library             String
Library             RPA.Outlook.Application
Library             RPA.Tables
Library             Collections
Library             RPA.FileSystem
Library             DateTime

Suite Teardown      Quit Application
Task Setup          Open Application


*** Variables ***
${Config}
${Locator}
${Global}=          ${True}
${Directory}        %{DIR}
${Account}          %{MAIL}
${BE}               %{BE}
${MSG}              %{MSG}
${CONFIG_NAME}      %{CONFIG_NAME}


*** Tasks ***
RPA Hackathon Level1 Task
    TRY
        Get Data From Config File
        Get Locator From Locator File
        Open Website
        Wait Until Keyword Succeeds    2    .05s    Logging in Application
        Navigate to Level 1
        ${inputData}=    Read Input File
        IF    ${Global}
            FOR    ${element}    IN    @{inputData}
                TRY
                    Wait Until Keyword Succeeds    2    .05s    Fill Forms    ${element}
                EXCEPT    AS    ${Exception}
                    ${msg}=    Set Variable    Bot is unable to fill the data:${element} due to Exception :${Exception}
                    # Set Global Variable    ${Global}    ${False}
                    Send Mail    ${Config}[AE]    ${msg}
                    Reload Page
                END
                Log To Console    Global:--${Global}
                IF    '${Global}' == 'False'                    BREAK
            END
        END

        Get Result
    EXCEPT    AS    ${Exception}
        Log To Console    Application Error:--${Exception}
        Send Mail    ${Config}[AE]    ${Exception}
    END


*** Keywords ***
Get Data From Config File
    ${Check1}=    Is Directory Empty    ${Directory}
    IF    ${Check1}
        Set Global Variable    ${Global}    ${False}
        Set Global Variable    ${Exception}    ${Directory} directory is Empty.
        Send Email    recipients=${Account}    subject=${BE}    body=${Exception}
    ELSE
        ${Check2}=    Does File Exist    ${CONFIG_NAME}
        IF    ${Check2}
            ${Check3}=    Is File Empty    ${CONFIG_NAME}
            IF    ${Check3}
                Set Global Variable    ${Global}    ${False}
                Send Email    recipients=${Account}    subject=${BE}    body=%{MSG1}
            ELSE
                ${json}=    Load JSON from file    ${CONFIG_NAME}
                Set Global Variable    ${Config}    ${json}
            END
        ELSE
            Set Global Variable    ${Global}    ${False}
            Send Email    recipients=${Account}    subject=${BE}    body=${MSG}
        END
    END

Send Mail
    [Arguments]    ${Subject}    ${Body}
    Log To Console    Exception is :----${Body}
    Send Email    recipients=${Config}[accountName]    subject=${Subject}    body=${Body}

Get Locator From Locator File
    IF    ${Global}
        ${Check}=    Does File Exist    ${Config}[Locator_File_Path]
        IF    ${Check}
            ${Check1}=    Is File Empty    ${Config}[Locator_File_Path]
            IF    ${Check1}
                Set Global Variable    ${Global}    ${False}
                Send Mail    ${Config}[BE]    ${Config}[Ex9]
            ELSE
                ${json}=    Load JSON from file    ${Config}[Locator_File_Path]
                Set Global Variable    ${Locator}    ${json}
            END
        ELSE
            Set Global Variable    ${Global}    ${False}
            Send Mail    ${Config}[BE]    ${Config}[Ex2]
        END
    END

Read Input File
    IF    ${Global}
        ${checkFile}=    Does File Exist    ${Config}[Input_File_Path]
        IF    ${checkFile}
            ${checkFileEmpty}=    Is File Not Empty    ${Config}[Input_File_Path]
            IF    ${checkFileEmpty}
                ${headers}=    Create List
                ...    ${Config}[headers][0][First Name]
                ...    ${Config}[headers][0][Last Name]
                ...    ${Config}[headers][0][Company Name]
                ...    ${Config}[headers][0][Role In Company]
                ...    ${Config}[headers][0][Address]
                ...    ${Config}[headers][0][E-Mail]
                ...    ${Config}[headers][0][Phone Number]
                ${input}=    Read table from CSV    ${Config}[Input_File_Path]    columns=${headers}
                Filter Empty Rows    ${input}

                ${rows}    ${columns}=    Get table dimensions    ${input}
                ${Data}=    Create List    " "    None
                TRY
                    Should Be Equal As Integers    ${rows}    ${Config}[Row]    ${Config}[Ex5]
                    Should Be Equal As Integers    ${columns}    ${Config}[Column]    ${Config}[Ex8]
                    FOR    ${row}    IN    @{input}
                        FOR    ${element}    IN    @{Data}
                            Log    ${element}

                            Should Not Contain
                            ...    ${row}[${Config}[headers][0][First Name]]
                            ...    ${element}
                            ...    ${Config}[Ex7]
                            Should Not Contain
                            ...    ${row}[${Config}[headers][0][Last Name]]
                            ...    ${element}
                            ...    ${Config}[Ex7]
                            Should Not Contain
                            ...    ${row}[${Config}[headers][0][Company Name]]
                            ...    ${element}
                            ...    ${Config}[Ex7]
                            Should Not Contain
                            ...    ${row}[${Config}[headers][0][Role In Company]]
                            ...    ${element}
                            ...    ${Config}[Ex7]
                            Should Not Contain
                            ...    ${row}[${Config}[headers][0][Address]]
                            ...    ${element}
                            ...    ${Config}[Ex7]
                            Should Not Contain    ${row}[${Config}[headers][0][E-Mail]]    ${element}    ${Config}[Ex7]
                            Should Not Contain
                            ...    ${row}[${Config}[headers][0][Phone Number]]
                            ...    ${element}
                            ...    ${Config}[Ex7]
                        END
                    END
                    ${time}=    Get Current Date    result_format=%d.%m.%Y-%H.%M
                    Move File    ${Config}[Input_File_Path]    ${Config}[Folder_Path]-${time}.csv
                    RETURN    ${input}
                EXCEPT    AS    ${except}
                    Set Global Variable    ${Global}    ${False}
                    Send Mail    ${Config}[BE]    ${except}
                END
            ELSE
                Set Global Variable    ${Global}    ${False}
                Send Mail    ${Config}[BE]    ${Config}[Ex4]
            END
        ELSE
            Set Global Variable    ${Global}    ${False}
            Send Mail    ${Config}[BE]    ${Config}[Ex3]
        END
    END

Open Website
    IF    ${Global}
        TRY
            Open Available Browser    ${Config}[URL]    maximized=True    browser_selection=${Config}[Browser]
        EXCEPT    AS    ${exception}
            Set Global Variable    ${Global}    ${False}
            Send Mail    ${Config}[AE]    ${Config}[Ex10]
        END
    END

Logging in Application
    IF    ${Global}
        Set Selenium Timeout    ${Config}[wl]
        ${secrets}=    Get Secret    ${Config}[Cred Name]
        Wait Until Element Is Visible    ${Locator}[inputUser]    error=${Config}[Ex1]
        Input Text When Element Is Visible    ${Locator}[inputUser]    ${secrets}[username]
        Input Password    ${Locator}[inputPassword]    ${secrets}[password]
        Submit Form
        ${checkError1}=    Does Page Contain Element    ${Locator}[elementUserFieldError]
        IF    ${checkError1}
            Set Global Variable    ${Global}    ${False}
            Send Mail    ${Config}[BE]    ${Config}[Ex6]
        END
        ${checkError2}=    Does Page Contain Element    ${Locator}[elementPasswwordFieldError]
        IF    ${checkError2}
            Set Global Variable    ${Global}    ${False}
            Send Mail    ${Config}[BE]    ${Config}[Ex6]
        END
        Page Should Contain Element    ${Locator}[btnLevel1]
    END

Navigate to Level 1
    IF    ${Global}
        Remove File    ${Config}[Input_File_Path]
        Click Element When Visible    ${Locator}[btnLevel1]    #Click on Level1
        Wait Until Element Is Visible    ${Locator}[tabLevel1]    # Check Level task opened or not
        Click Element When Visible    ${Locator}[btnStart_Level_1]    #Click on Start Level1 Btn
        Click Element When Visible    ${Locator}[dropdownTools]    #Click on Dropdown
        Input Text When Element Is Visible    ${Locator}[dropdownField]    Robot Framework
        Press Keys    ${Locator}[dropdownField]    RETURN    #Press Enter
        #Sleep    3
        Click Element When Visible    ${Locator}[btnDownload_CSV]    #Download CSV File
        Submit Form    #Click on Start
        Page Should Contain Element    ${Locator}[elementTimer]    Step1 is not opened
    END

Fill Forms
    [Arguments]    ${Data}
    IF    ${Global}
        ${Check1}=    Does Page Contain Element    ${Locator}[popupWindow]
        IF    ${Check1}
            Log to Console    ${Data}[${Config}[headers][0][First Name]]

            #Click on A
            ${c1}=    Does Page Contain    ${Config}[A]
            IF    ${c1}
                ${BtnA}=    Does Page Contain Button    ${Locator}[btnPopup_A]
                IF    ${BtnA}
                    Wait Until Element Is Visible    ${Locator}[btnPopup_A]
                    Set Focus To Element    ${Locator}[btnPopup_A]
                    Click Element When Visible    ${Locator}[btnPopup_A]
                END
            ELSE
                #Click on B
                ${c2}=    Does Page Contain    ${Config}[B]
                IF    ${c2}
                    ${BtnB}=    Does Page Contain Button    ${Locator}[btnPopup_B]
                    IF    ${BtnB}
                        Wait Until Element Is Visible    ${Locator}[btnPopup_B]
                        Set Focus To Element    ${Locator}[btnPopup_B]
                        Double Click Element    ${Locator}[btnPopup_B]
                    END
                ELSE
                    #Click on Cancel
                    ${c6}=    Does Page Contain    ${Config}[CANCEL]
                    IF    ${c6}
                        ${BtnCancel}=    Does Page Contain Button    ${Locator}[btnPopup_Cancel]
                        IF    ${BtnCancel}
                            Wait Until Element Is Visible    ${Locator}[btnPopup_Cancel]
                            Set Focus To Element    ${Locator}[btnPopup_Cancel]
                            Click Element When Visible    ${Locator}[btnPopup_Cancel]
                        END
                    ELSE
                        #Click on OK
                        ${c5}=    Does Page Contain    ${Config}[OK]
                        IF    ${c5}
                            ${BtnOK}=    Does Page Contain Button    ${Locator}[btnPopup_Ok]
                            IF    ${BtnOK}
                                Wait Until Element Is Visible    ${Locator}[btnPopup_Ok]
                                Set Focus To Element    ${Locator}[btnPopup_Ok]
                                Click Element When Visible    ${Locator}[btnPopup_Ok]
                            END
                        ELSE
                            #Click on C
                            ${c3}=    Does Page Contain    ${Config}[C]
                            IF    ${c3}
                                ${BtnC}=    Does Page Contain Button    ${Locator}[btnPopup_C]
                                IF    ${BtnC}
                                    Wait Until Element Is Visible    ${Locator}[btnPopup_C]
                                    Set Focus To Element    ${Locator}[btnPopup_C]
                                    Click Button When Visible    ${Locator}[btnPopup_C]
                                END
                            ELSE
                                #Click on Goofy
                                ${c4}=    Does Page Contain    ${Config}[GOOFY]
                                IF    ${c4}
                                    ${BtnGoofy}=    Does Page Contain Button    ${Locator}[btnPopup_Goofy]
                                    IF    ${BtnGoofy}
                                        ${data1}=    Get Text    ${Locator}[btnPopup_Goofy]
                                        IF    "${data1}" == "GOOFY"
                                            Log To Console    Goofy:---${data1}
                                            Wait Until Element Is Visible    ${Locator}[btnPopup_Goofy]
                                            Set Focus To Element    ${Locator}[btnPopup_Goofy]
                                            Click Element When Visible    ${Locator}[btnPopup_Goofy]
                                        ELSE
                                            Log To Console    Click On Close
                                            Wait Until Element Is Visible    ${Locator}[btnPopup_Close]
                                            Set Focus To Element    ${Locator}[btnPopup_Close]
                                            Click Element When Visible    ${Locator}[btnPopup_Close]
                                        END
                                    END
                                ELSE
                                    #Click on OSWALD
                                    ${c7}=    Does Page Contain    ${Config}[OSWALD]
                                    IF    ${c7}
                                        ${BtnOSWALD}=    Does Page Contain Button    ${Locator}[btnPopup_Oswald]
                                        IF    ${BtnOSWALD}
                                            ${data2}=    Get Text    ${Locator}[btnPopup_Oswald]

                                            IF    "${data2}" == "OSWALD"
                                                Log To Console    OSWALD:---${data2}
                                                Wait Until Element Is Visible    ${Locator}[btnPopup_Oswald]
                                                Set Focus To Element    ${Locator}[btnPopup_Oswald]
                                                Click Element When Visible    ${Locator}[btnPopup_Oswald]
                                            ELSE
                                                Log To Console    Click On Close
                                                Wait Until Element Is Visible    ${Locator}[btnPopup_Close]
                                                Set Focus To Element    ${Locator}[btnPopup_Close]
                                                Click Element When Visible    ${Locator}[btnPopup_Close]
                                            END
                                        END
                                    END
                                END
                            END
                        END
                    END
                END
            END
        END
    END

    Wait Until Element Is Visible    ${Locator}[inputFirstName]
    Set Focus To Element    ${Locator}[inputFirstName]
    Input Text When Element Is Visible    ${Locator}[inputFirstName]    ${Data}[${Config}[headers][0][First Name]]

    Wait Until Element Is Visible    ${Locator}[inputLastName]
    Set Focus To Element    ${Locator}[inputLastName]
    Input Text When Element Is Visible    ${Locator}[inputLastName]    ${Data}[${Config}[headers][0][Last Name]]

    Set Focus To Element    ${Locator}[inputCompanyName]
    Wait Until Element Is Visible    ${Locator}[inputCompanyName]
    Input Text When Element Is Visible
    ...    ${Locator}[inputCompanyName]
    ...    ${Data}[${Config}[headers][0][Company Name]]

    Wait Until Element Is Visible    ${Locator}[inputRole_in_Company]
    Set Focus To Element    ${Locator}[inputRole_in_Company]
    Input Text When Element Is Visible
    ...    ${Locator}[inputRole_in_Company]
    ...    ${Data}[${Config}[headers][0][Role In Company]]

    Wait Until Element Is Visible    ${Locator}[inputAddress]
    Set Focus To Element    ${Locator}[inputAddress]
    Input Text When Element Is Visible    ${Locator}[inputAddress]    ${Data}[${Config}[headers][0][Address]]

    Wait Until Element Is Visible    ${Locator}[inputEmail]
    Set Focus To Element    ${Locator}[inputEmail]
    Input Text When Element Is Visible    ${Locator}[inputEmail]    ${Data}[${Config}[headers][0][E-Mail]]

    Wait Until Element Is Visible    ${Locator}[inputPhone_Number]
    Set Focus To Element    ${Locator}[inputPhone_Number]
    Input Text When Element Is Visible
    ...    ${Locator}[inputPhone_Number]
    ...    ${Data}[${Config}[headers][0][Phone Number]]

    Wait Until Element Is Visible    ${Locator}[btnForm_Submit]
    Set Focus To Element    ${Locator}[btnForm_Submit]
    Click Element When Visible    ${Locator}[btnForm_Submit]

Get Result
    IF    ${Global}
        ${data}=    Get Text    ${Locator}[elementResult]
        Log To Console    Result:--${data}
        Send Email    recipients=${Config}[accountName]    subject=${Config}[Subject1]    body=${data}
    END
