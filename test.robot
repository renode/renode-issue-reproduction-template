*** Comments ***
Execution tracing bug testcase.  Tracing is enabled on line 165 of this file

*** Variables ***
${SRAM_BASE_S}               0x20020000
${SRAM_BASE_NS}              0x30020000
${IMU_BASE_S}                0x44008000
${EUSART0_BASE_S}            0x40208000
${EUSART0_BASE_NS}           0x50208000
${EUSART0_PERIPH_IDX}        45
${SRAM_CPU0_SYNC}            0x20020550
${SRAM_CPU0_CODE_S}          0x20021000
${SRAM_CPU0_STACKTOP_S}      0x20021F80
${SRAM_CPU0_CODE_NS}         0x30023000
${SRAM_CPU0_STACKTOP_NS}     0x30023F80

${REPL_STRING}=  SEPARATOR=\n
...  """
...  sram: Memory.MappedMemory @ {
...  ${SPACE*8}sysbus ${SRAM_BASE_S};
...  ${SPACE*8}sysbus ${SRAM_BASE_NS}
...  ${SPACE*4}}
...  ${SPACE*4}size: 0x80000
...
...  nvic0: IRQControllers.NVIC @ sysbus new Bus.BusPointRegistration {
...  ${SPACE*8}address: 0xE000E000;
...  ${SPACE*8}cpu: cpu0
...  ${SPACE*4}}
...  ${SPACE*4}-> cpu0@0
...  cpu0: CPU.CortexM @ sysbus
...  ${SPACE*4}cpuType: "cortex-m33"
...  ${SPACE*4}nvic: nvic0
...  ${SPACE*4}cpuId: 0
...  ${SPACE*4}enableTrustZone: true
...
...  imu: Python.PythonPeripheral @ sysbus new Bus.BusPointRegistration { address: ${IMU_BASE_S} }
...  ${SPACE*4}size: 0x4
...  ${SPACE*4}initable: false
...  ${SPACE*4}script: "request.value = 0"
...
...  eusart0: UART.EFR32xG2_EUSART_2 @ {
...  ${SPACE*8}sysbus <${EUSART0_BASE_S}, +0x4000>;
...  ${SPACE*8}sysbus <${EUSART0_BASE_NS}, +0x4000>
...  ${SPACE*4}}
...  ${SPACE*4}clockFrequency: 39000000
...  """

${TRUSTZONE_TEST_S}=  SEPARATOR=\n
...     ldr sp,=${SRAM_CPU0_STACKTOP_S}
...     ldr r1,=${IMU_BASE_S}
...     mov r2,#${EUSART0_PERIPH_IDX}
...     adr r3,cpu0_strings
...     ldr r4,=${EUSART0_BASE_S}
...     ldr r0,=${SRAM_CPU0_CODE_NS}
...     ldr r11,[r0,#4] // r11 = initial PC from nonsecure vector table
...     bic r11,#1 // blxns instr expects bit[0] clear for branch to nonsecure
...     bl str_print // hello
...     // configure SAU region 0
...     // start=(SRAM_CPU0_CODE_NS) limit=(SRAM_CPU0_STACKTOP_NS) nonsecure
...     ldr r9,=0xe000edd0
...     mov r10,#0
...     str r10,[r9,#0x8] // SAU->RNR = 0
...     str r0,[r9,#0xc] // SAU->RBAR = (SRAM_CPU0_CODE_NS)
...     ldr r10,=${SRAM_CPU0_STACKTOP_NS}+0x1
...     str r10,[r9,#0x10] // SAU->RLAR = (SRAM_CPU0_STACKTOP_NS) | (nonsecure)
...     // configure SAU region 1
...     // start=0x50000000 limit=0x5fffffe0 nonsecure
...     mov r10,#1
...     str r10,[r9,#0x8] // SAU->RNR = 1
...     ldr r10,=0x50000000
...     str r10,[r9,#0xc] // SAU->RBAR = 0x50000000
...     ldr r10,=0x5fffffe1
...     str r10,[r9,#0x10] // SAU->RLAR = 0x5fffffe0 | (nonsecure)
...     // enable SAU
...     mov r10,#3
...     str r10,[r9] // SAU->CTRL = (enable) | (allns)
...     // set nonsecure vector table ptr
...     ldr r9,=0xe002ed08
...     str r0,[r9] // SCB->VTOR_NS = (SRAM_CPU0_CODE_NS)
...     // initialize MSP_NS
...     ldr r10,[r0]
...     msr msp_ns,r10
...     // synchronization barrier
...     dsb
...     isb
...     // ready to call nonsecure
...     blxns r11 // test 1
...     mov r10,#1
...     mov r9,r2
...     and r9,#0x1f
...     lsl r10,r9 // r10 = mask for eusart vector
...     mov r6,r2
...     lsr r6,#5
...     lsl r6,#2
...     add r6,r6,r1 // r6 = imu base + offset for eusart in bit vector
...
...     // test 2,3: clear eusart tz mask
...     mov r8,#0x2060 // PPU_SecureAttribute0_Clr
...     add r9,r6,r8
...     str r10,[r9]
...     bl str_print // test 2
...     blxns r11 // test 3
...
...     // test 4,5: set eusart tz mask
...     mov r8,#0x1060 // PPU_SecureAttribute0_Set
...     add r9,r6,r8
...     str r10,[r9]
...     bl str_print // test 4
...     blxns r11 // test 5
...     b end_test
...  cpu0_strings:
...     .asciz "Hello from cpu0 secure\\n"
...     .asciz "Test 2 good\\n"
...     .asciz "Test 4 good\\n"
...     .align 3
...

${TRUSTZONE_TEST_NS}=  SEPARATOR=\n
...  // nonsecure vector table
...     .word ${SRAM_CPU0_STACKTOP_NS} // initial SP
...     .word ${SRAM_CPU0_CODE_NS}+0x201 // initial PC = nonsecure_print
...     .fill (64-2),4,0 // unused vectors
...  nonsecure_str_ptr:
...     .word ${SRAM_CPU0_CODE_NS}+0x104 // nonsecure_strings
...  nonsecure_strings:
...     .asciz "Test 1 good\\n"
...     .asciz "Test 3 good\\n"
...     .asciz "Test 5 good\\n"
...     .align 9 // hack to get org to ${SRAM_CPU0_CODE_NS}+0x200
...  nonsecure_print:
...     push {r3,r4,r5,r7,lr}
...     ldr r4,=${EUSART0_BASE_NS}
...     ldr r5,=${SRAM_CPU0_CODE_NS}+0x100 // nonsecure_str_ptr
...     ldr r3,[r5]
...  1: ldrb r7,[r3] // iterate chars in string
...     add r3,r3,#1
...     cbz r7,2f
...     str r7,[r4,#0x44] // write char to eusart.TxData
...     b 1b
...  2: str r3,[r5]
...     pop {r3,r4,r5,r7,pc}
...

${COMMON_ASM}=  SEPARATOR=\n
...  str_print:
...  // r3 contains pointer to string (will advance to next string)
...  // r4 contains eusart reg base
...     push {r7,lr}
...  1: ldrb r7,[r3] // iterate chars in string
...     add r3,r3,#1
...     cbz r7,2f
...     str r7,[r4,#0x44] // write char to eusart.TxData
...     b 1b
...  2: pop {r7,pc}
...
...  end_test:
...     wfi
...     b end_test
...

*** Keywords ***
Create Machine
    Execute Command         mach create
    Execute Command         machine LoadPlatformDescriptionFromString ${REPL_STRING}
    Execute Command         sysbus.cpu0 CreateExecutionTracing "cpu0_tracer" @artifacts/cpu0_disasm Disassembly
    Execute Command         emulation SetGlobalSerialExecution true
    Execute Command         sysbus LogAllPeripheralsAccess true
    Execute Command         logLevel 1

Eusart Async Init
    [Arguments]  ${eusart}=sysbus.eusart0
    Execute Command         ${eusart} WriteDoubleWord 0x10 0x20 # Cfg_2
    Execute Command         ${eusart} WriteDoubleWord 0xC 0x0 # Cfg_1
    Execute Command         ${eusart} WriteDoubleWord 0x8 0x0 # Cfg_0
    Execute Command         ${eusart} WriteDoubleWord 0x14 0x1002 # FrameCfg
    Execute Command         ${eusart} WriteDoubleWord 0x18 0x0 # DtxDataCfg
    Execute Command         ${eusart} WriteDoubleWord 0x58 0x0 # DaliCfg
    Execute Command         ${eusart} WriteDoubleWord 0x24 0x50000 # TimingCfg
    Execute Command         ${eusart} WriteDoubleWord 0x1C 0x0 # IrHfCfg
    Execute Command         ${eusart} WriteDoubleWord 0x20 0x0 # IrLfCfg
    Execute Command         ${eusart} WriteDoubleWord 0x28 0x0 # StartFrameCfg
    Execute Command         ${eusart} WriteDoubleWord 0x2C 0x0 # SigFrameCfg
    Execute Command         ${eusart} WriteDoubleWord 0x34 0x0 # TriggerControl
    Execute Command         ${eusart} WriteDoubleWord 0x50 0x0 # InterruptEnable
    Execute Command         ${eusart} WriteDoubleWord 0x4C 0x0 # InterruptFlag
    Execute Command         ${eusart} WriteDoubleWord 0x30 0x0 # ClkDiv
    Execute Command         ${eusart} WriteDoubleWord 0x14 0x1002 # FrameCfg
    Execute Command         ${eusart} WriteDoubleWord 0x8 0x0 # Cfg_0
    Execute Command         ${eusart} WriteDoubleWord 0x4 0x1 # Enable
    Execute Command         ${eusart} WriteDoubleWord 0x38 0x5 # Command
    Execute Command         ${eusart} WriteDoubleWord 0x30 0x7FFF00 # ClkDiv
    Execute Command         ${eusart} WriteDoubleWord 0x4 0x1 # Enable
    Execute Command         ${eusart} WriteDoubleWord 0x38 0x5 # Command

Trustzone Test
    [Arguments]             ${cpu}=sysbus.cpu0
    Execute Command         ${cpu} AssembleBlock ${SRAM_CPU0_CODE_S} """${TRUSTZONE_TEST_S}${COMMON_ASM}"""
    Execute Command         ${cpu} AssembleBlock ${SRAM_CPU0_CODE_NS} """${TRUSTZONE_TEST_NS}"""
    Execute Command         ${cpu} PC ${SRAM_CPU0_CODE_S}
    Start Emulation
    Wait For Line On Uart   Hello from cpu0 secure
    Wait For Line On Uart   Test 1 good
    Wait For Line On Uart   Test 2 good
    Wait For Line On Uart   Test 3 good
    Wait For Line On Uart   Test 4 good
    Wait For Line On Uart   Test 5 good

*** Test Cases ***
Trustzone
    Create Machine
    Eusart Async Init       eusart=sysbus.eusart0
    Execute Command         showAnalyzer sysbus.eusart0
    Create Terminal Tester  sysbus.eusart0
    Trustzone Test

