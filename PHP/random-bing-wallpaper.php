<?php
// 获取随机的日期索引
$idx = rand(0, 7); // Bing API只提供过去7天的壁纸，所以索引范围是0到7

// Bing API URL，带随机索引
$bing_url = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=$idx&n=1&mkt=en-US";

// 获取Bing的JSON数据
$json_data = @file_get_contents($bing_url); // 使用@来抑制警告信息
if ($json_data === FALSE) {
    // 如果获取数据失败，返回错误信息
    header("HTTP/1.1 500 Internal Server Error");
    echo "Failed to retrieve data from Bing.";
    exit;
}

$data = json_decode($json_data, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    // 如果JSON解码失败，返回错误信息
    header("HTTP/1.1 500 Internal Server Error");
    echo "Failed to decode JSON data.";
    exit;
}

// 提取图片URL
if (!isset($data['images'][0]['url'])) {
    // 如果URL不存在，返回错误信息
    header("HTTP/1.1 500 Internal Server Error");
    echo "Image URL not found in Bing response.";
    exit;
}

$image_url = "https://www.bing.com" . $data['images'][0]['url'];

// 进行HTTP重定向
header("Location: $image_url");
exit;
?>
