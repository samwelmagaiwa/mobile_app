<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Database\DatabaseManager;
use App\Helpers\NumberHelper;

class DatabaseShowCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'db:show-safe {--database= : The database connection to use}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Display database information (MySQL 5.7 & no-intl compatible)';

    /**
     * Execute the console command.
     */
    public function handle(DatabaseManager $db): int
    {
        $connection = $db->connection($this->option('database'));
        
        try {
            $this->info('Database Information:');
            $this->line('');
            
            // Database name
            $this->line('Database: ' . $connection->getDatabaseName());
            
            // Connection info
            $config = $connection->getConfig();
            $this->line('Host: ' . ($config['host'] ?? 'Unknown'));
            $this->line('Port: ' . ($config['port'] ?? 'Unknown'));
            $this->line('Username: ' . ($config['username'] ?? 'Unknown'));
            
            // Try to get MySQL version
            try {
                $version = $connection->selectOne('SELECT VERSION() as version');
                $this->line('Version: ' . ($version->version ?? 'Unknown'));
            } catch (\Exception $e) {
                $this->line('Version: Unable to determine');
            }
            
            // Try to get database size
            try {
                $sizeQuery = "
                    SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb
                    FROM information_schema.tables 
                    WHERE table_schema = ?
                ";
                $result = $connection->selectOne($sizeQuery, [$connection->getDatabaseName()]);
                $sizeMb = $result->size_mb ?? 0;
                $this->line('Size: ' . NumberHelper::fileSize($sizeMb * 1024 * 1024));
            } catch (\Exception $e) {
                $this->line('Size: Unable to determine');
            }
            
            // Try to get table count
            try {
                $tableCount = $connection->selectOne("
                    SELECT COUNT(*) as count 
                    FROM information_schema.tables 
                    WHERE table_schema = ?
                ", [$connection->getDatabaseName()]);
                $this->line('Tables: ' . ($tableCount->count ?? 0));
            } catch (\Exception $e) {
                $this->line('Tables: Unable to determine');
            }
            
            // Try to get connection count (MySQL 5.7 compatible)
            try {
                if ($connection instanceof \App\Database\MySqlConnection57) {
                    $threadCount = $connection->threadCount();
                    $this->line('Connections: ' . ($threadCount ?? 'Unknown'));
                } else {
                    $threads = $connection->selectOne("SHOW STATUS LIKE 'Threads_connected'");
                    $this->line('Connections: ' . ($threads->Value ?? 'Unknown'));
                }
            } catch (\Exception $e) {
                $this->line('Connections: Unable to determine');
            }
            
            $this->line('');
            $this->info('✅ Database information retrieved successfully');
            
            return Command::SUCCESS;
            
        } catch (\Exception $e) {
            $this->error('Failed to retrieve database information: ' . $e->getMessage());
            return Command::FAILURE;
        }
    }
}