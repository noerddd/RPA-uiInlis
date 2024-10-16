*** Settings ***
Library     RPA.Browser.Selenium    auto_close=${False}
Library     Collections
Library     RPA.JSON
Library     RPA.Database
Library     RPA.HTTP
Library     RPA.FileSystem
Library     OperatingSystem
Library     String


*** Variables ***
${API_URL}      http://103.106.72.182:8770
${BOOK_ID}      ${EMPTY}
${BROWSER}      Firefox
${URL}          http://localhost/inlislite3/backend/site/login


*** Test Cases ***
Get JSON Data From API
    ${book_id}=    Set Variable    ${BOOK_ID}
    Create Session    mysession    ${API_URL}    verify=${False}
    ${response}=    GET On Session    mysession    /api/getBookSinopsis/${book_id}

    # Decode the response content from bytes to string using UTF-8 encoding
    ${response_str}=    Decode Bytes To String    ${response.content}    encoding=UTF-8

    # Log the raw response content
    Log To Console    Raw Response: ${response_str}

    # Clean the response by escaping double quotes
    ${clean_response}=    Replace String    ${response_str}    "    \\"    # Escape double quotes
    ${clean_response}=    Replace String    ${clean_response}    \n    \\n    # Escape newlines
    ${clean_response}=    Replace String    ${clean_response}    \r    \\r    # Escape carriage returns

    # Remove any unnecessary trailing newline characters
    ${clean_response}=    Strip String    ${clean_response}

    # Log cleaned response to verify
    Log To Console    Cleaned Response: ${clean_response}

    # Try to convert the cleaned string into dictionary
    ${json_data}=    Convert To Dictionary    ${clean_response}
    Log To Console    Full JSON Response: ${json_data}

    # Set global variables from JSON data
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

Otomatisasi Entri Katalog
    Open Browser    ${URL}    ${BROWSER}
    Login website
    Select Library Location
    Click Submit Button
    Navigate to Entri Katalog (RDA)
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
    ...    ${ILUSTRATOR}
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

Navigate to Entri Katalog (RDA)
    Wait Until Element Is Visible
    ...    xpath=//li[@class="treeview"]/a[contains(@href, '/pengkatalogan/katalog/index')]
    ...    timeout=10s
    Click Element    xpath=//li[@class="treeview"]/a[contains(@href, '/pengkatalogan/katalog/index')]
    Wait Until Element Is Visible
    ...    xpath=//li/a[@href='/inlislite3/backend/pengkatalogan/katalog/create?for=cat&rda=1']
    ...    timeout=10s
    Click Element    xpath=//li/a[@href='/inlislite3/backend/pengkatalogan/katalog/create?for=cat&rda=1']

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
    ...    ${ilustrator}

    # Cek jika pengarang ada lebih dari satu, pisahkan berdasarkan koma
    ${pengarang_list}=    Split String    ${pengarang}    ;

    Wait Until Element Is Visible    id:TagsValue_245    timeout=10s
    Run Keyword And Ignore Error    Execute JavaScript    document.getElementById('TagsValue_245').value += '${judul}';
    Run Keyword And Ignore Error
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_100').value += '${pengarang_list[0]}';
    Run Keyword And Ignore Error
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_264_0').value += '${penerbitan}';
    Run Keyword And Ignore Error
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_300').value += '${desc}';
    Run Keyword And Ignore Error
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_020_0').value += '${isbn}';
    Run Keyword And Ignore Error    Execute JavaScript    document.getElementById('TagsValue_043').value += '${kota}';
    ${jumlah_pengarang}=    Get Length    ${pengarang_list}
    FOR    ${index}    IN RANGE    1    ${jumlah_pengarang}
        ${pengarang_ke_n}=    Set Variable    ${pengarang_list[${index}]}
        Run Keyword And Ignore Error
        ...    Execute JavaScript
        ...    document.getElementById('TagsValue_700_0').value += '${pengarang_ke_n};';
    END
    Run Keyword And Ignore Error
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_700_0').value += '${editor};';
    Run Keyword And Ignore Error
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_700_0').value += '${ilustrator};';
    Run Keyword And Ignore Error
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_520_0').value += '${sinopsis}';
    Run Keyword And Ignore Error
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_650_0').value += '${keyword}';
    Run Keyword And Continue On Failure    Click Button    id:btnSave2
    Log To Console    Form telah disubmit.

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
