*** Settings ***
Library     SeleniumLibrary
Library     Collections
Library     RPA.JSON
Library     RPA.Database
Library     RPA.HTTP
Library     RPA.FileSystem
Library     OperatingSystem
Library     String


*** Variables ***
${BASE_API_URL}     http://127.0.0.1:8770
${BOOK_ID}          ${EMPTY}
${IP_ADDRESS}       ${EMPTY}
${URL}              http://${IP_ADDRESS}/inlislite3/backend/site/login
${PASSWORD}         otobook1234
${USERNAME}         root
${DB_NAME}          inlis
${DB_HOST}          localhost
${DB_PORT}          3306
${DOWNLOAD_PATH}    /var/www/html/inlislite3/uploaded_files/sampul_koleksi/original/Monograf
${KODE_WILAYAH}     ${EMPTY}
${USERNAME_USER}    ${EMPTY}
${PASSWORD_USER}    ${EMPTY}


*** Test Cases ***
Get JSON Data From API
    ${book_id}=    Set Variable    ${BOOK_ID}
    Create Session    mysession    ${BASE_API_URL}    verify=${False}
    ${response}=    GET On Session    mysession    /api/getBookSinopsis/${book_id}

    # Decode the response content from bytes to string using UTF-8 encoding
    ${response_str}=    Decode Bytes To String    ${response.content}    encoding=UTF-8

    Log To Console    Response: ${response_str}
    # Clean the response by escaping necessary characters
    ${clean_response}=    Replace String    ${response_str}    "    \\"    
    ${clean_response}=    Replace String    ${clean_response}    '    \\'    
    ${clean_response}=    Replace String    ${clean_response}    \n    \\n    
    ${clean_response}=    Replace String    ${clean_response}    \r    \\r    
    ${clean_response}=    Replace String    ${clean_response}    \t    \\t    # Escape tabs

    Log To Console    Cleaned Response: ${clean_response}
    # Remove any unnecessary trailing newline characters
    ${clean_response}=    Strip String    ${clean_response}

    # Try to convert the cleaned string into dictionary
    ${json_data}=    Convert To Dictionary    ${clean_response}

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
    Set Global Variable    ${NOCLASS}    ${json_data['no_class']}

Otomatisasi Entri Katalog
    ${username_user}=    Set Variable    ${USERNAME_USER}
    ${password_user}=    Set Variable    ${PASSWORD_USER}
    ${options}=    Evaluate    selenium.webdriver.ChromeOptions()    modules=selenium.webdriver
    Call Method    ${options}    add_argument    --no-sandbox
    Call Method    ${options}    add_argument    --disable-notifications
    Call Method    ${options}    add_argument    --headless
    Create WebDriver    Chrome    options=${options}
    Go To    ${URL}
    Sleep    2s
    Login website
    Sleep    2s
    Select Library Location
    Sleep    2s
    Click Submit Button
    Sleep    2s
    Navigate to Entri Katalog (RDA)
    Sleep    2s
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
    ...    ${NOCLASS}
    ...    ${KODE_WILAYAH}
    Sleep    2s
    Logout website
    Sleep    2s
    Close Browser
    Sleep    2s

Operation
    Download Image
    Connect To Database    pymysql    ${DB_NAME}    ${USERNAME}    ${PASSWORD}    ${DB_HOST}    ${DB_PORT}
    ${exists}=    Check If Book Exists    ${ISBN}
    ${cover_url}=    Set Variable    ${ISBN}.jpg
    Log To Console    Checking ISBN: ${ISBN} and CoverURL: ${cover_url}
    IF    ${exists}
        Query    UPDATE catalogs SET CoverURL = '${cover_url}' WHERE ISBN = '${ISBN}';
        Query    COMMIT;
        Log To Console    CoverURL updated to ${cover_url} for Book ISBN ${ISBN}
        Query    SELECT CoverURL FROM catalogs WHERE ISBN = '${ISBN}';
    ELSE
        Log To Console    message: Book with ISBN ${ISBN} was not found
    END
    Sleep    5s
    Disconnect From Database


*** Keywords ***
Convert To Dictionary
    [Arguments]    ${json_string}
    ${json_data}=    Evaluate    json.loads('''${json_string}''')    json
    RETURN    ${json_data}

Login website
    Input Text    id:loginform-username    ${username_user}
    Input Text    id:loginform-password    ${password_user}
    Click Button    name:login-button

Select Library Location
    Wait Until Element Is Visible    xpath=//span[@id="select2-dynamicmodel-location-container"]    timeout=10s
    Click Element    xpath=//span[@id="select2-dynamicmodel-location-container"]
    Wait Until Element Is Visible    xpath=//li[contains(text(), 'Perpustakaan Pusat')]    timeout=10s
    Click Element    xpath=//li[contains(text(), 'Perpustakaan Pusat')]

Click Submit Button
    Click Button    //button[@class="btn btn-primary btn-block btn-flat button_login"]

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
    ...    ${no_class}
    ...    ${kode_wilayah}

    # Cek jika pengarang ada lebih dari satu, pisahkan berdasarkan koma
    ${pengarang_list}=    Split String    ${pengarang}    ;

    Wait Until Element Is Visible    id:TagsValue_245    timeout=10s
    Run Keyword    Execute JavaScript    document.getElementById('TagsValue_245').value += "${judul}";
    Run Keyword
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_100').value += "${pengarang_list[0]}";
    Run Keyword
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_264_0').value += "${penerbitan}";
    Run Keyword
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_300').value += "${desc}";
    Run Keyword
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_020_0').value += "${isbn}";
    Run Keyword    Execute JavaScript    document.getElementById('TagsValue_043').value += "${kota}";
    ${jumlah_pengarang}=    Get Length    ${pengarang_list}
    FOR    ${index}    IN RANGE    0    ${jumlah_pengarang}
        ${pengarang_ke_n}=    Set Variable    ${pengarang_list[${index}]}
        Run Keyword
        ...    Execute JavaScript
        ...    document.getElementById('TagsValue_700_0').value += '${pengarang_ke_n};';
    END

    Run Keyword
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_700_0').value += "${editor};";
    Run Keyword
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_700_0').value += "${ilustrator};";
    Run Keyword And Ignore Error
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_850_0').value += '${kode_wilayah}';
    Run Keyword
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_520_0').value += "${sinopsis}";
    Run Keyword
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_650_0').value += "${keyword}";
    Run Keyword
    ...    Execute JavaScript
    ...    document.getElementById('TagsValue_082_0').value += "${no_class}";
    Run Keyword    Click Button    id:btnSave2
    Log To Console    Form telah disubmit.

Logout Website
    Wait Until Element Is Not Visible    css=div.modal-backdrop    timeout=20s
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


Check If Book Exists
    [Arguments]    ${ISBN}
    ${cover_url}=    Set Variable    ${ISBN}.jpg
    ${query}=    Set Variable    SELECT COUNT(*) FROM catalogs WHERE ISBN = '${ISBN}';
    Log To Console    Executing Query: ${query}
    ${result}=    Query    ${query}
    Log To Console    Query Result: ${result}
    ${count}=    Set Variable    ${result}[0][0]

    IF    ${count} > 0
        Log To Console    Book with ISBN ${ISBN} exists
        RETURN    ${True}
    ELSE
        Log To Console    Book with ISBN ${ISBN} does not exist
        RETURN    ${False}
    END


Download Image
    ${API_URL}=    Set Variable    ${BASE_API_URL}/api/sendCover/${BOOK_ID}
    ${file_path}=    Set Variable    ${DOWNLOAD_PATH}/${ISBN}.jpg
    Download    ${API_URL}    ${file_path}
    Log To Console    Gambar berhasil diunduh ke ${file_path}
