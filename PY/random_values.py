import json
from datetime import datetime, timedelta

# 配置文件路径
CONFIG_FILE = 'random_values.json'

# 初始化配置文件
def init_config():
    if not os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, 'w') as f:
            json.dump({}, f)

# 读取配置文件
def read_config():
    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)

# 写入配置文件
def write_config(config):
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=4)

# 生成随机 User-Agent (可根据需要扩展此函数)
def generate_user_agent(device_type='default'):
    if device_type == 'ios':
        return 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1'
    elif device_type == 'android':
        return 'Mozilla/5.0 (Linux; Android 11; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36'
    else:
        return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'

# 更新随机值
def update_random_values(script_name, values):
    config = read_config()
    now = datetime.now()

    if script_name not in config:
        config[script_name] = {}

    for key, val in values.items():
        if key not in config[script_name]:
            config[script_name][key] = {'value': val(), 'last_update': now.isoformat()}
        else:
            last_update = datetime.fromisoformat(config[script_name][key]['last_update'])
            if (key.startswith('user_agent') and now - last_update > timedelta(days=3)) or \
               (key == 'sleep' and now - last_update > timedelta(seconds=1)) or \
               (key == 'random_string' and now - last_update > timedelta(days=1)):
                config[script_name][key]['value'] = val()
                config[script_name][key]['last_update'] = now.isoformat()

    write_config(config)

# 获取随机值
def get_random_values(script_name):
    config = read_config()
    return config.get(script_name, {})

# 使用示例脚本
if __name__ == "__main__":
    script_name = 'example_script'
    
    # 定义需要的随机值
    values = {
        'user_agent_ios': lambda: generate_user_agent('ios'),
        'user_agent_android': lambda: generate_user_agent('android')
    }
    
    # 更新并获取随机值
    update_random_values(script_name, values)
    random_values = get_random_values(script_name)
    
    # 打印获取到的随机值
    print("iOS User-Agent:", random_values.get('user_agent_ios', {}).get('value'))
    print("Android User-Agent:", random_values.get('user_agent_android', {}).get('value'))

    # 模拟遍历操作
    for ua_key in ['user_agent_ios', 'user_agent_android']:
        ua_value = random_values.get(ua_key, {}).get('value')
        print(f"Using {ua_key}: {ua_value}")
        # 这里可以添加具体的操作代码，例如发送请求等
