<?php

require 'vendor/autoload.php';

use Aws\S3\S3Client;
use Aws\Exception\AwsException;
$s3Client = new S3Client([
    'version' => 'latest',
    'region'  => 'ap-southt-1',
]);

$bucketName = 'equipassesment';

$path = isset($_GET['path']) ? $_GET['path'] : '';

header('Content-Type: application/json');

try {
    $params = [
        'Bucket' => $bucketName,
        'Prefix' => $path,
        'Delimiter' => '/',
    ];

    $result = $s3Client->listObjectsV2($params);
    $content = [];

    if (isset($result['CommonPrefixes'])) {
        foreach ($result['CommonPrefixes'] as $prefix) {
            $content[] = basename(rtrim($prefix['Prefix'], '/'));
        }
    }

    if (isset($result['Contents'])) {
        foreach ($result['Contents'] as $object) {
            $content[] = basename($object['Key']);
        }
    }

    echo json_encode(['content' => $content]);

} catch (AwsException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}

?>
