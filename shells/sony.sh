#!/bin/bash
# wget -O sony.sh https://raw.githubusercontent.com/wukongdaily/tvhelper-docker/master/shells/sony.sh && chmod +x sony.sh && ./sony.sh
#********************************************************

# 定义红色文本
RED='\033[0;31m'
# 无颜色
NC='\033[0m'
GREEN='\e[38;5;154m'
YELLOW="\e[93m"
BLUE="\e[96m"

# 菜单选项数组
declare -a menu_options
declare -A commands

# 检查输入是否为整数
is_integer() {
    if [[ $1 =~ ^-?[0-9]+$ ]]; then
        return 0 # 0代表true/成功
    else
        return 1 # 非0代表false/失败
    fi
}

# 判断adb是否连接成功
check_adb_connected() {
    # 获取 adb devices 输出,跳过第一行（标题行）,并检查每一行的状态
    local connected_devices=$(adb devices | awk 'NR>1 {print $2}' | grep 'device$')
    # 检查是否有设备已连接并且状态为 'device',即已授权
    if [[ -n $connected_devices ]]; then
        # ADB 已连接并且设备已授权
        return 0
    else
        # ADB 设备未连接或未授权
        return 1
    fi
}

# 连接adb
connect_adb() {
    echo -e "${BLUE}请手动输入电视盒子的IP地址:${NC}"
    read ip
    
    adb disconnect
    echo -e "${BLUE}首次使用,盒子上可能会提示授权弹框,给您半分钟时间来操作...【允许】${NC}"
    adb connect ${ip}

    # 循环检测连接状态
    for ((i = 1; i <= 30; i++)); do
        echo -e "${YELLOW}第${i}次尝试连接ADB,请在设备上点击【允许】按钮...${NC}"
        device_status=$(adb devices | grep "${ip}:5555" | awk '{print $2}')
        if [[ "$device_status" == "device" ]]; then
            echo -e "${GREEN}ADB 已经连接成功啦,你可以放心操作了${NC}"
            return 0
        fi
        sleep 1 # 每次检测间隔1秒
    done
    echo -e "${RED}连接超时,或者您点击了【取消】,请确认电视盒子的IP地址是否正确。如果问题持续存在,请检查设备的USB调试设置是否正确并重新连接adb${NC}"
}

# 显示当前时区
show_timezone() {
    adb shell getprop persist.sys.timezone
}

#断开adb连接
disconnect_adb() {
    adb disconnect
    echo "ADB 已经断开"
}

get_status() {
    if check_adb_connected; then
        adb_status="${GREEN}已连接且已授权${NC}"
    else
        adb_status="${RED}未连接${NC}"
    fi
    echo -e "*      与电视盒子的连接状态:$adb_status"
}

# 获取电视盒子型号
get_tvbox_model_name() {
    if check_adb_connected; then
        # 获取设备型号
        local model=$(adb shell getprop ro.product.model)
        # 获取设备制造商
        local manufacturer=$(adb shell getprop ro.product.manufacturer)
        # 清除换行符
        model=$(echo $model | tr -d '\r' | tr -d '\n')
        manufacturer=$(echo $manufacturer | tr -d '\r' | tr -d '\n')
        echo -e "*      当前电视盒子型号:${BLUE}$manufacturer $model${NC}"
    else
        echo -e "*      当前电视盒子型号:${BLUE}请先连接ADB${NC}"
    fi
}

# 获取电视盒子时区
get_tvbox_timezone() {
    if check_adb_connected; then
        # 获取设备时区
        device_timezone=$(adb shell getprop persist.sys.timezone)
        # 获取设备系统时间，格式化为“年月日 时:分”
        device_time=$(adb shell date "+%Y年%m月%d日 %H:%M")

        echo -e "*      当前电视盒子时区:${YELLOW}$device_timezone${NC}"
        echo -e "*      当前电视盒子时间:${YELLOW}$device_time${NC}"
    else
        echo -e "*      当前电视盒子时区:${BLUE}请先连接ADB${NC}"
        echo -e "*      当前电视盒子时间:${BLUE}请先连接ADB${NC}"
    fi
}

# 能否访问Github
check_github_connected() {
    # Ping GitHub域名并提取时间
    ping_time=$(ping -c 1 raw.githubusercontent.com | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')

    if [ -n "$ping_time" ]; then
        echo -e "*      当前路由器访问Github延时:${BLUE}${ping_time}ms${NC}"
    else
        echo -e "*      当前路由器访问Github延时:${RED}超时${NC}"
    fi
}

# 安装Netflix
install_netflix() {
    local app_name_dir="netflix"
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/netflix/netflix.apk" $app_name_dir
    install_app_bundle $app_name_dir
}

# 安装Disney+
install_disney() {
    local app_name_dir="disney"
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/disney/disney.apk" $app_name_dir
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/disney/split_config.xhdpi.apk" $app_name_dir
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/disney/split_config.zh.apk" $app_name_dir
    install_app_bundle $app_name_dir
}

# 安装Fire TV版本Youtube
install_youtube() {
    install_apk "https://github.com/wukongdaily/tvhelper/raw/master/apks/youtube.apk"
}

# 安装HBO GO
install_hbogo() {
    local app_name_dir="hbogo"
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/hbogo/hbo-go.apk" $app_name_dir
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/hbogo/split_config.xhdpi.apk" $app_name_dir
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/hbogo/split_config.zh.apk" $app_name_dir
    install_app_bundle $app_name_dir
}

# 安装appletv+
install_appletv() {
    local app_name_dir="appletv"
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/appletv/appletv.apk" $app_name_dir
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/appletv/split_config.armeabi_v7a.apk" $app_name_dir
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/appletv/split_config.es.apk" $app_name_dir
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/appletv/split_config.xhdpi.apk" $app_name_dir
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/appletv/split_config.zh.apk" $app_name_dir
    install_app_bundle $app_name_dir
}
# 安装mytvsuper
install_mytvsuper() {
    local app_name_dir="mytvsuper"
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/mytvsuper/mytvsuper.apk" $app_name_dir
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/mytvsuper/split_config.xhdpi.apk" $app_name_dir
    download_apk "https://github.com/wukongdaily/tvhelper/raw/master/sony/mytvsuper/split_config.zh.apk" $app_name_dir
    install_app_bundle $app_name_dir
}

# 下载单独apk
# 保存在/tmp/应用名称的文件夹下
download_apk() {
    local apk_download_url=$1
    local app_name_dir=$2
    local filename=$(basename "$apk_download_url")
    # 下载APK文件到临时目录
    mkdir -p "/tmp/${app_name_dir}"
    wget -O "/tmp/${app_name_dir}/${filename}" "$apk_download_url"
}

# 根据文件夹名称,安装文件夹中全部apk
install_app_bundle() {
    local app_name_dir=$1
    if check_adb_connected; then
        echo -e "${GREEN}正在推送和安装apk,请耐心等待...${NC}"

        # 模拟安装进度
        echo -ne "${BLUE}"
        while true; do
            echo -n ".."
            sleep 1
        done &

        # 保存进度指示进程的PID
        PROGRESS_PID=$!
        install_result=$(adb install-multiple -r /tmp/${app_name_dir}/*.apk 2>&1)

        # 安装完成后,终止进度指示进程
        kill $PROGRESS_PID
        wait $PROGRESS_PID 2>/dev/null
        echo -e "${NC}\n"

        # 检查安装结果
        if [[ $install_result == *"Success"* ]]; then
            echo -e "${GREEN}APK安装成功!请在盒子上查看${NC}"
        else
            echo -e "${RED}APK安装失败:$install_result${NC}"
        fi
        rm -rf "/tmp/${app_name_dir}"
        echo -e "${YELLOW}临时文件/tmp/${app_name_dir}文件夹已清理${NC}"
    else
        connect_adb
    fi
}

# 安装apk
install_apk() {
    local apk_download_url=$1
    local filename=$(basename "$apk_download_url")
    # 下载APK文件到临时目录
    wget -O /tmp/$filename "$apk_download_url"
    if check_adb_connected; then
        echo -e "${GREEN}正在推送和安装apk,请耐心等待...${NC}"

        # 模拟安装进度
        echo -ne "${BLUE}"
        while true; do
            echo -n ".."
            sleep 1
        done &

        # 保存进度指示进程的PID
        PROGRESS_PID=$!
        install_result=$(adb install -r /tmp/$filename 2>&1)

        # 安装完成后,终止进度指示进程
        kill $PROGRESS_PID
        wait $PROGRESS_PID 2>/dev/null
        echo -e "${NC}\n"

        # 检查安装结果
        if [[ $install_result == *"Success"* ]]; then
            echo -e "${GREEN}APK安装成功!请在盒子上查看${NC}"
        else
            echo -e "${RED}APK安装失败:$install_result${NC}"
        fi
        rm -rf /tmp/"$filename"
        echo -e "${YELLOW}临时文件/tmp/${filename}已清理${NC}"
    else
        connect_adb
    fi
}

sponsor() {
    echo
    echo -e "${GREEN}访问赞助页面和悟空百科⬇${BLUE}"
    echo -e "${BLUE} https://bit.ly/3woDZE7 ${NC}"
    echo
}

# 菜单
menu_options=(
    "连接ADB"
    "断开ADB"
    "安装Netflix最新版"
    "安装Apple TV+最新版"
    "安装Disney+最新版"
    "安装HBO GO最新版"
    "安装myTVSuper最新版"
    "安装Youtube-FireTV版"
    "赞助|打赏"
)

commands=(
    ["连接ADB"]="connect_adb"
    ["断开ADB"]="disconnect_adb"
    ["安装Netflix最新版"]="install_netflix"
    ["安装Disney+最新版"]="install_disney"
    ["安装Youtube-FireTV版"]="install_youtube"
    ["安装HBO GO最新版"]="install_hbogo"
    ["安装Apple TV+最新版"]="install_appletv"
    ["安装myTVSuper最新版"]="install_mytvsuper"
    ["赞助|打赏"]="sponsor"
)

# 处理菜单
handle_choice() {
    local choice=$1
    # 检查输入是否为空
    if [[ -z $choice ]]; then
        echo -e "${RED}输入不能为空,请重新选择。${NC}"
        return
    fi

    # 检查输入是否为数字
    if ! [[ $choice =~ ^[0-9]+$ ]]; then
        echo -e "${RED}请输入有效数字!${NC}"
        return
    fi

    # 检查数字是否在有效范围内
    if [[ $choice -lt 1 ]] || [[ $choice -gt ${#menu_options[@]} ]]; then
        echo -e "${RED}选项超出范围!${NC}"
        echo -e "${YELLOW}请输入 1 到 ${#menu_options[@]} 之间的数字。${NC}"
        return
    fi

    local selected_option="${menu_options[$choice - 1]}"
    local command_to_run="${commands[$selected_option]}"

    # 检查是否存在对应的命令
    if [ -z "$command_to_run" ]; then
        echo -e "${RED}无效选项,请重新选择。${NC}"
        return
    fi

    # 使用eval执行命令
    eval "$command_to_run"
}

show_menu() {
    current_date=$(date +%Y%m%d)
    clear
    echo "***********************************************************************"
    echo -e "*      ${YELLOW}Sony电视专用助手Docker版  (${current_date})${NC}        "
    echo -e "*      ${RED}请确保电视盒子和Docker宿主机处于${NC}${BLUE}同一网段${NC}\n*      ${RED}且电视盒子开启了${NC}${BLUE}USB调试模式(adb开关)${NC}         "
    echo "*      Developed by @wukongdaily        "
    echo "**********************************************************************"
    echo
    echo "$(get_status)"
    echo "$(get_tvbox_model_name)"
    echo "$(get_tvbox_timezone)"
    echo
    echo "**********************************************************************"
    echo "请选择操作："
    for i in "${!menu_options[@]}"; do
        echo -e "${BLUE}$((i + 1)). ${menu_options[i]}${NC}"
    done
}

while true; do
    show_menu
    read -p "请输入选项的序号(输入q退出): " choice
    if [[ $choice == 'q' ]]; then
        break
    fi
    handle_choice $choice
    echo "按任意键继续..."
    read -n 1 # 等待用户按键
done
