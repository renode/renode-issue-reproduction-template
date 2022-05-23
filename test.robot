*** Settings ***
Suite Setup                   Setup
Suite Teardown                Teardown
Test Setup                    Reset Emulation
Test Teardown                 Test Teardown
Resource                      ${RENODEKEYWORDS}

*** Variables ***
${SCRIPT}                     ${CURDIR}/test.resc
${UART}                       sysbus.uart


*** Keywords ***
Load Script
    Execute Script            ${SCRIPT}
    Create Terminal Tester    ${UART}


*** Test Cases ***
Should Run Test Case
    Load Script
    Start Emulation
    Wait For Prompt On Uart     uart:~$
    Write Line To Uart
    Wait For Prompt On Uart     uart:~$
    Write Line To Uart          demo ping
    Wait For Line On Uart       pong
