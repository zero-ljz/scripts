#!/usr/bin/env php
<?php
/*
 * 这是一个 Symfony Console 程序 （PHP CLI APP）
 * 文档
 * https://symfony.com/doc/current/components/console.html
 *
 * 安装依赖库
 * composer require symfony/console
 *
 * 使用
 * php encoder.php base64 'Hello, world!'
 * php encoder.php base64 -d 'SGVsbG8sIHdvcmxkIQ=='
 *
 * 或者 
 * chmod 755 encoder.php
 * ./encoder.php base64 "Hello, world!"
*/

require __DIR__.'/vendor/autoload.php';

use Symfony\Component\Console\Application;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputOption;

$application = new Application();

$application->register('base64')
    ->addArgument('text', InputArgument::REQUIRED, 'Text to encode/decode')
    ->addOption('decode', 'd', InputOption::VALUE_NONE, 'Perform decoding')
    ->setDescription('Base64 encoding/decoding')
    ->setCode(function (InputInterface $input, OutputInterface $output) {
        $text = $input->getArgument('text');
        $decoded = $input->getOption('decode');

        if ($decoded) {
            $output->writeln(base64_decode($text));
        } else {
            $output->writeln(base64_encode($text));
        }
    });

// Define other commands here...

$application->run();

