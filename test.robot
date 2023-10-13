*** Settings ***
Library     Telnet


*** Variables ***
${REPL}                             rtc.repl

# Registers
${Control}                          0x0
${Mode}                             0x4
${Prescaler}                        0x8
${AlarmLow}                         0xC
${AlarmHigh}                        0x10
${CompareLow}                       0x14
${CompareHigh}                      0x18
${DateTimeLow}                      0x20
${DateTimeHigh}                     0x24
${DateTimeSynchronizedSeconds}      0x30
${DateTimeSynchronizedMinutes}      0x34
${DateTimeSynchronizedHours}        0x38
${DateTimeSynchronizedDay}          0x3C
${DateTimeSynchronizedMonth}        0x40
${DateTimeSynchronizedYear}         0x44
${DateTimeSynchronizedWeekday}      0x48
${DateTimeSynchronizedWeek}         0x4C
${DateTimeSeconds}                  0x50
${DateTimeMinutes}                  0x54
${DateTimeHours}                    0x58
${DateTimeDay}                      0x5C
${DateTimeMonth}                    0x60
${DateTimeYear}                     0x64
${DateTimeWeekday}                  0x68
${DateTimeWeek}                     0x6C


*** Test Cases ***
RTC Test Functionality
    Create Machine
# Stop timer if running
    Execute Command    sysbus WriteDoubleWord ${Control} 0x2
    ${temp} =    Execute Command    sysbus ReadDoubleWord ${Control}
    Should Contain    ${temp}    0x00000000
# Reset registers to 0
    Execute Command    sysbus WriteDoubleWord ${Control} 0x08
    Execute Command    sysbus WriteDoubleWord ${AlarmLow} 0x0
    Execute Command    sysbus WriteDoubleWord ${AlarmHigh} 0x0
    Execute Command    sysbus WriteDoubleWord ${CompareLow} 0x0
    Execute Command    sysbus WriteDoubleWord ${CompareHigh} 0x0
    Execute Command    sysbus WriteDoubleWord ${Control} 0x0
# Set Prescaler
    Execute Command    sysbus WriteDoubleWord ${Prescaler} 0x3E7
# Initialise the RTC
    Execute Command    sysbus WriteDoubleWord ${DateTimeLow} 0x0
    Execute Command    sysbus WriteDoubleWord ${DateTimeHigh} 0x0

    Execute Command    sysbus WriteDoubleWord ${Control} 0x20
    ${temp} =    Execute Command    sysbus ReadDoubleWord ${Control}
    Should Contain    ${temp}    0x00000000
# Set Alarm value
    Execute Command    sysbus WriteDoubleWord ${Control} 0x08
    Execute Command    sysbus WriteDoubleWord ${AlarmLow} 0xA
    Execute Command    sysbus WriteDoubleWord ${AlarmHigh} 0x0
    Execute Command    sysbus WriteDoubleWord ${CompareLow} 0xFFFFFFFF
    Execute Command    sysbus WriteDoubleWord ${CompareHigh} 0xFFFFFFFF
    Execute Command    sysbus WriteDoubleWord ${Mode} 0x0E
    Execute Command    sysbus WriteDoubleWord ${Control} 0x04
    Execute Command    sysbus WriteDoubleWord ${Control} 0x01


*** Keywords ***
Create Machine
    Execute Command    using sysbus
    Execute Command    mach create
    Execute Command
    ...    machine LoadPlatformDescriptionFromString "rtc: Timers.MPFS_RTC @ sysbus 0x0"
