*** Settings ***
Library     RPA.Browser.Selenium    auto_close=${False}
Library     Collections
Library     RPA.JSON
Library     RPA.Database
Library     RPA.HTTP
Library     RPA.FileSystem
Library     OperatingSystem


*** Variables ***
${API_URL}      http://103.106.72.182:8770
${BOOK_ID}      ${EMPTY}
${BROWSER}      Chrome
${URL}          http://103.106.72.182:8772/inlislite3/backend/site/login


*** Test Cases ***
Get JSON Data From API
    # Masukkan username dan password sesuai dengan kebutuhan

    ${book_id}=    Set Variable    ${BOOK_ID}
    Create Session    mysession    ${API_URL}    verify=${False}
    ${response}=    GET On Session    mysession    /api/getBookSinopsis/${book_id}
    ${json_data}=    Convert To Dictionary    ${response.content}
    Log To Console    Full JSON Response: ${json_data}

    # Set global variables
    Set Global Variable    ${JUDUL}    ${json_data['judul']}
    Set Global Variable    ${PENGARANG}    ${json_data['pengarang']}
    Set Global Variable    ${PENERBITAN}    ${json_data['penerbitan']}
    Set Global Variable    ${DESC}    ${json_data['deskripsi']}
    Set Global Variable    ${ISBN}    ${json_data['isbn']}
    Set Global Variable    ${KOTA}    ${json_data['kota']}
    Set Global Variable    ${TAHUN}    ${json_data['tahun']}
    Set Global Variable    ${EDITOR}    ${json_data['editor']}
    Set Global Variable    ${ILUSTRATOR}    ${json_data['ilustrator']}
    Set Global Variable    ${SINOPSIS}    ${json_data['sinopsis']}
    Set Global Variable    ${KEYWORD}    ${json_data['keyword']}

Test Open Browser
    [Documentation]    Opens the browser in headless mode using a built-in keyword
    ${idx}=    Open Headless Chrome Browser    ${URL}
    Login website
    Select Library Location
    Click Submit Button
    Navigate to Entri Katalog
    Input Book Data
    ...    ${JUDUL}
    ...    ${PENGARANG}
    ...    ${PENERBITAN}
    ...    ${DESC}
    ...    ${ISBN}
    ...    ${KOTA}
    ...    ${EDITOR}
    ...    ${SINOPSIS}
    ...    ${KEYWORD}
    Logout website
    Close Browser


*** Keywords ***
Convert To Dictionary
    [Arguments]    ${json_string}
    ${json_data}=    Evaluate    json.loads('''${json_string}''')    json
    RETURN    ${json_data}

Login website
    Input Text    id:loginform-username    inlislite
    Input Text    id:loginform-password    inlislite=
    Click Button    name:login-button

Select Library Location
    Wait Until Element Is Visible    xpath=//span[@id="select2-dynamicmodel-location-container"]    timeout=10s
    Click Element    xpath=//span[@id="select2-dynamicmodel-location-container"]
    Wait Until Element Is Visible    xpath=//li[contains(text(), 'Perpustakaan Pusat')]    timeout=10s
    Click Element    xpath=//li[contains(text(), 'Perpustakaan Pusat')]

Click Submit Button
    Click Button When Visible    //button[@class="btn btn-primary btn-block btn-flat button_login"]

Navigate to Entri Katalog
    Wait Until Element Is Visible
    ...    xpath=//li[@class="treeview"]/a[contains(@href, '/pengkatalogan/katalog/index')]
    ...    timeout=10s
    Click Element    xpath=//li[@class="treeview"]/a[contains(@href, '/pengkatalogan/katalog/index')]
    Wait Until Element Is Visible
    ...    xpath=//li/a[@href='/inlislite3/backend/pengkatalogan/katalog/create?for=cat&rda=0']
    ...    timeout=10s
    Click Element    xpath=//li/a[@href='/inlislite3/backend/pengkatalogan/katalog/create?for=cat&rda=0']

Input Book Data
    [Arguments]
    ...    ${judul}
    ...    ${pengarang}
    ...    ${penerbitan}
    ...    ${desc}
    ...    ${isbn}
    ...    ${kota}
    ...    ${editor}
    ...    ${sinopsis}
    ...    ${keyword}
    Wait Until Element Is Visible    id:TagsValue_245    timeout=10s
    Run Keyword and Ignore Error    Execute JavaScript    document.getElementById('TagsValue_245').value += ${judul};
    Run Keyword and Ignore Error
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_100').value += ${pengarang};
    Run Keyword and Ignore Error
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_260_0').value += ${penerbitan};
    Run Keyword and Ignore Error    Execute JavaScript    document.getElementById('TagsValue_500_0').value += ${desc};
    Run Keyword and Ignore Error    Execute JavaScript    document.getElementById('TagsValue_020_0').value += ${isbn};
    Run Keyword and Ignore Error    Execute JavaScript    document.getElementById('TagsValue_043').value += ${kota};
    Run Keyword and Ignore Error
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_700_0').value += ${editor};
    Run Keyword and Ignore Error
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_520_0').value += ${sinopsis};
    Run Keyword and Ignore Error    Execute JavaScript    document.getElementById('TagsValue_504').value += ${keyword};
    Click Button    id:btnSave2

Logout Website
    Wait Until Element Is Not Visible    css=div.modal-backdrop    timeout=30s
    Execute JavaScript    swal.close();
    Wait Until Element Is Visible
    ...    xpath=//li[@class="dropdown user user-menu"]/a[contains(@class, 'dropdown-toggle')]
    ...    timeout=30s
    Click Element    xpath=//li[@class="dropdown user user-menu"]/a[contains(@class, 'dropdown-toggle')]
    ${logout_element}=    Execute JavaScript
    ...    return document.querySelector("a[href='/inlislite3/backend/site/logout']");
    IF    '${logout_element}' == None
        Fail    Logout link not found in the DOM
    END
    Execute JavaScript    document.querySelector("a[href='/inlislite3/backend/site/logout']").click();

Close Browser
    Close All Browsers
