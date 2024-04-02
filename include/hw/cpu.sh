# This file contains basic CPU commands together with cpu_execute function

# CPU COMMAND #
export CPU_EQUAL_CMD="is_equal"
export CPU_NOT_EQUAL_CMD="is_not_equal"
export CPU_ADD_CMD="add"
export CPU_INCREMENT_CMD="increment"
export CPU_DECREMENT_CMD="decrement"
export CPU_SUBTRACT_CMD="subtract"
export CPU_MULTIPLY_CMD="multiply"
export CPU_DIVIDE_CMD="divide"
export CPU_CONCAT_CMD="concat"
export CPU_CONCAT_SPACES_CMD="concat_spaces"
export CPU_GET_COLUMN_CMD="get_column"
export CPU_REPLACE_COLUMN_CMD="replace_column"
export CPU_LESS_THAN_CMD="less_than"
export CPU_LESS_THAN_EQUAL_CMD="less_than_equal"
export CPU_STARTS_WITH_CMD="starts_with"
export CPU_ENCRYPT_CMD="encrypt"
export CPU_DECRYPT_CMD="decrypt"
export CPU_CORRECT_PATH_CMD="correct_path"
export CPU_REMOVE_FREE_RANGE_CMD="remove_free_range"
export CPU_GET_FREE_RANGE_CMD="get_free_range"
export CPU_UPDATE_FREE_RANGE_CMD="update_free_range"

# CPU execution function

# function to execute CPU command provided as the first argument of the function
# Input arguments(if needed) should be stored to RAM
# and corresponding addresses should be provided as the second and the third arguments of the function
# Result is stored into GLOBAL_OUTPUT_ADDRESS for all commands except comparison which stored into GLOBAL_COMPARE_RES_ADDRESS
function cpu_execute {
    local CPU_REGISTER_CMD="${1}"
    local CPU_REGISTER1=""
    local CPU_REGISTER2=""
    local CPU_REGISTER3=""
    local CPU_REGISTER_OUT=""

    if [ ! -z "$2" ]; then
        CPU_REGISTER1="$(read_from_address ${2})"
    fi
    if [ ! -z "$3" ]; then
        CPU_REGISTER2="$(read_from_address ${3})"
    fi
    if [ ! -z "$4" ]; then
        CPU_REGISTER3="$(read_from_address ${4})"
    fi

    case "${CPU_REGISTER_CMD}" in
        "${CPU_EQUAL_CMD}")
            if [ "${CPU_REGISTER1}" = "${CPU_REGISTER2}" ]; then
                CPU_REGISTER_OUT="1"
            else
                CPU_REGISTER_OUT="0"
            fi
            write_to_address ${GLOBAL_COMPARE_RES_ADDRESS} "${CPU_REGISTER_OUT}"
            return 0
            ;;
        "${CPU_NOT_EQUAL_CMD}")
            if [ "${CPU_REGISTER1}" != "${CPU_REGISTER2}" ]; then
                CPU_REGISTER_OUT="1"
            else
                CPU_REGISTER_OUT="0"
            fi
            write_to_address ${GLOBAL_COMPARE_RES_ADDRESS} ${CPU_REGISTER_OUT}
            return 0
            ;;
        "${CPU_LESS_THAN_CMD}")
            if [ "${CPU_REGISTER1}" -lt "${CPU_REGISTER2}" ]; then
                CPU_REGISTER_OUT="1"
            else
                CPU_REGISTER_OUT="0"
            fi
            write_to_address ${GLOBAL_COMPARE_RES_ADDRESS} ${CPU_REGISTER_OUT}
            return 0
            ;;
         "${CPU_LESS_THAN_EQUAL_CMD}")
            if [ "${CPU_REGISTER1}" -le "${CPU_REGISTER2}" ]; then
                CPU_REGISTER_OUT="1"
            else
                CPU_REGISTER_OUT="0"
            fi
            write_to_address ${GLOBAL_COMPARE_RES_ADDRESS} ${CPU_REGISTER_OUT}
            return 0
            ;;
        "${CPU_ADD_CMD}")
            CPU_REGISTER_OUT="$((${CPU_REGISTER1}+${CPU_REGISTER2}))"
            ;;
        "${CPU_SUBTRACT_CMD}")
            CPU_REGISTER_OUT="$((${CPU_REGISTER1}-${CPU_REGISTER2}))"
            ;;
        "${CPU_INCREMENT_CMD}")
            CPU_REGISTER_OUT="$((${CPU_REGISTER1}+1))"
            ;;
        "${CPU_DECREMENT_CMD}")
            CPU_REGISTER_OUT="$((${CPU_REGISTER1}-1))"
            ;;
        "${CPU_CONCAT_CMD}")
            CPU_REGISTER_OUT="${CPU_REGISTER1}${CPU_REGISTER2}"
            ;;
        "${CPU_CONCAT_SPACES_CMD}")
            if [ -z "${CPU_REGISTER2}" ]; then
                CPU_REGISTER_OUT="${CPU_REGISTER1}"
            elif [ -z "${CPU_REGISTER1}" ]; then
                CPU_REGISTER_OUT="${CPU_REGISTER2}"
            else
                CPU_REGISTER_OUT="${CPU_REGISTER1} ${CPU_REGISTER2}"
            fi
            ;;
        "${CPU_GET_COLUMN_CMD}")
            CPU_REGISTER_OUT=$(echo "${CPU_REGISTER1}" | awk -F' ' ' {print $'${CPU_REGISTER2}'}')
            ;;
        "${CPU_REPLACE_COLUMN_CMD}")
            CPU_REGISTER_OUT=$(echo "${CPU_REGISTER1}" | awk -F' ' '{$'${CPU_REGISTER2}'='${CPU_REGISTER3}'}1' )
            ;;
        "${CPU_STARTS_WITH_CMD}")
            if [[ "${CPU_REGISTER1}" == "${CPU_REGISTER2}"* ]]; then
                CPU_REGISTER_OUT="1"
            else
                CPU_REGISTER_OUT="0"
            fi
            write_to_address ${GLOBAL_COMPARE_RES_ADDRESS} "${CPU_REGISTER_OUT}"
            if [ "${CPU_REGISTER_OUT}" == "1" ]; then
                CPU_REGISTER_OUT=${CPU_REGISTER1#${CPU_REGISTER2}}
                write_to_address ${GLOBAL_OUTPUT_ADDRESS} "${CPU_REGISTER_OUT}"
            fi
            return 0
            ;;
        "${CPU_ENCRYPT_CMD}"|"${CPU_DECRYPT_CMD}")
            local INPUT="${CPU_REGISTER1}"
            local OUTPUT=""
            for ((i = 0; i < ${#INPUT}; i+=2)); do
                local PAIR=$(echo "${INPUT:$i:2}" | tr '[:lower:][:upper:]' '[:upper:][:lower:]')
                local SWAPPED_PAIR=${PAIR:1:1}${PAIR:0:1}
                OUTPUT+=$SWAPPED_PAIR
            done
            CPU_REGISTER_OUT="${OUTPUT}"
            ;;
        "${CPU_CORRECT_PATH_CMD}")
            if [[ "${CPU_REGISTER1:0:5}" == "/mnt/" ]]; then
                CPU_REGISTER_OUT="1"
            else
                CPU_REGISTER_OUT="0"
            fi
            ;;
        "${CPU_REMOVE_FREE_RANGE_CMD}")
            local INPUT="${CPU_REGISTER1%%FREE_RANGE: *}FREE_RANGE: "
            local START_ADDRESS="${CPU_REGISTER2}"
            local END_ADDRESS="${CPU_REGISTER3}"
            local FREE_RANGE_LIST=($( echo "${CPU_REGISTER1#*FREE_RANGE: }" | tr ' ' '\n' ))
            local NEW_LIST=()

            for ((i=0; i<${#FREE_RANGE_LIST[@]}; i+=2)); do
                if (( END_ADDRESS + 1 == FREE_RANGE_LIST[i+2] && START_ADDRESS - 1 == FREE_RANGE_LIST[i+1] )); then
                    NEW_LIST+=("${FREE_RANGE_LIST[i]}")
                    NEW_LIST+=("${FREE_RANGE_LIST[i+3]}")
                    i=$((i+4))
                    continue
                elif (( END_ADDRESS + 1 == FREE_RANGE_LIST[i] )); then
                    NEW_LIST+=("$START_ADDRESS")
                    NEW_LIST+=("${FREE_RANGE_LIST[i+1]}")
                elif (( END_ADDRESS + 1 < FREE_RANGE_LIST[i] )); then
                    NEW_LIST+=("$START_ADDRESS")
                    NEW_LIST+=("$END_ADDRESS")
                    NEW_LIST+=("${FREE_RANGE_LIST[i]}")
                    NEW_LIST+=("${FREE_RANGE_LIST[i+1]}")
                elif (( START_ADDRESS - 1 == FREE_RANGE_LIST[i+1] )); then
                    NEW_LIST+=("${FREE_RANGE_LIST[i]}")
                    NEW_LIST+=("$END_ADDRESS")
                else
                    NEW_LIST+=("${FREE_RANGE_LIST[i]}")
                    NEW_LIST+=("${FREE_RANGE_LIST[i+1]}")
                fi
            done

            local NEW_LIST_STR="${NEW_LIST[*]}"
            CPU_REGISTER_OUT="${INPUT}${NEW_LIST_STR% }"
            ;;
        "${CPU_GET_FREE_RANGE_CMD}")
            local INPUT="${CPU_REGISTER1%%FREE_RANGE: *}FREE_RANGE: "
            local FREE_RANGE_LIST=($( echo "${CPU_REGISTER1#*FREE_RANGE: }" | tr ' ' '\n' ))
            local MEM_COUNT="${CPU_REGISTER2}"
            local RESULT=""
            local OK=false

            for ((i=0; i<${#FREE_RANGE_LIST[@]}; i+=2)); do
                if (( 1 + FREE_RANGE_LIST[i+1] - FREE_RANGE_LIST[i] >= MEM_COUNT )); then
                    RESULT="$((i+7))"
                    OK=true
                    break
                fi
            done

            if [ "${OK}" = false ]; then
                RESULT="-1"
            fi

            CPU_REGISTER_OUT="${RESULT}"
            ;;
        "${CPU_UPDATE_FREE_RANGE_CMD}")
            local INPUT="${CPU_REGISTER1%%FREE_RANGE: *}FREE_RANGE: "
            local FREE_RANGE_LIST=($( echo "${CPU_REGISTER1#*FREE_RANGE: }" | tr ' ' '\n' ))
            local OLD_MEM_COUNT="${CPU_REGISTER2}"
            local NEW_MEM_COUNT="${CPU_REGISTER3}"
            local NEW_LIST=()

            for ((i=0; i<${#FREE_RANGE_LIST[@]}; i+=2)); do
                if (( FREE_RANGE_LIST[i] == OLD_MEM_COUNT )); then
                    if (( NEW_MEM_COUNT > FREE_RANGE_LIST[i+1] )); then
                        NEW_LIST+=("${FREE_RANGE_LIST[i+2]}")
                        NEW_LIST+=("${FREE_RANGE_LIST[i+3]}")
                        i=$((i+4))
                        continue
                    else 
                        NEW_LIST+=("${NEW_MEM_COUNT}")
                        NEW_LIST+=("${FREE_RANGE_LIST[i+1]}")
                    fi
                else
                    NEW_LIST+=("${FREE_RANGE_LIST[i]}")
                    NEW_LIST+=("${FREE_RANGE_LIST[i+1]}")
                fi
            done

            local NEW_LIST_STR="${NEW_LIST[*]}"
            CPU_REGISTER_OUT="${INPUT}${NEW_LIST_STR% }"
            ;;
        *)
    esac
    write_to_address ${GLOBAL_OUTPUT_ADDRESS} "${CPU_REGISTER_OUT}"
}

export -f cpu_execute
