<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex">
    <title>{{ $brand }} API</title>
    <style>
        :root {
            --bg-top: #04121a;
            --bg-mid: #092d3a;
            --bg-bottom: #0d485a;
            --accent: #20b8ce;
            --ok: #10b981;
            --bad: #f59e0b;
            --text: #ffffff;
            --muted: rgba(255, 255, 255, 0.7);
            --line: rgba(255, 255, 255, 0.14);
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px 16px;
            font-family: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            color: var(--text);
            background: linear-gradient(180deg, var(--bg-top) 0%, var(--bg-mid) 55%, var(--bg-bottom) 100%);
            background-attachment: fixed;
        }

        .card {
            width: 100%;
            max-width: 640px;
            padding: 44px 40px 28px;
            border-radius: 32px;
            border: 1px solid var(--line);
            background: rgba(255, 255, 255, 0.06);
            box-shadow: 0 30px 80px rgba(0, 0, 0, 0.35);
            text-align: center;
        }

        h1 {
            margin: 6px 0 0;
            font-size: 36px;
            font-weight: 800;
            letter-spacing: -0.5px;
        }

        .pill {
            display: inline-flex;
            align-items: center;
            gap: 12px;
            margin: 30px 0;
            padding: 14px 26px;
            border-radius: 999px;
            font-size: 19px;
            font-weight: 600;
            border: 1px solid var(--ok);
            background: rgba(16, 185, 129, 0.18);
        }

        .pill .dot {
            width: 14px;
            height: 14px;
            border-radius: 50%;
            background: var(--ok);
            box-shadow: 0 0 10px var(--ok);
        }

        .pill.bad { border-color: var(--bad); background: rgba(245, 158, 11, 0.16); }
        .pill.bad .dot { background: var(--bad); box-shadow: 0 0 10px var(--bad); }

        dl { margin: 0; border-top: 1px solid var(--line); }

        .row {
            display: flex;
            justify-content: space-between;
            gap: 16px;
            padding: 16px 4px;
            border-bottom: 1px solid var(--line);
            font-size: 18px;
        }

        .row dt { color: var(--muted); }
        .row dd { margin: 0; font-weight: 700; text-align: right; }
        .row dd.good { color: var(--ok); }
        .row dd.warn { color: var(--bad); }

        .button {
            display: inline-block;
            margin: 30px 0 22px;
            padding: 14px 30px;
            border-radius: 14px;
            border: 1.5px solid var(--accent);
            color: var(--accent);
            font-size: 18px;
            font-weight: 600;
            text-decoration: none;
        }

        .button:hover, .button:focus-visible { background: rgba(32, 184, 206, 0.14); }

        footer { color: var(--muted); font-size: 15px; }

        @media (max-width: 480px) {
            .card { padding: 32px 20px 22px; border-radius: 26px; }
            h1 { font-size: 28px; }
            .row, .pill { font-size: 16px; }
        }
    </style>
</head>
<body>
    <main class="card">
        <h1>{{ $brand }} API</h1>

        <div class="pill {{ $online ? '' : 'bad' }}" role="status">
            <span class="dot" aria-hidden="true"></span>
            {{ $online ? 'The API is running' : 'The API is having trouble' }}
        </div>

        <dl>
            <div class="row">
                <dt>Status</dt>
                <dd class="{{ $online ? 'good' : 'warn' }}">{{ $online ? 'Online' : 'Degraded' }}</dd>
            </div>
            <div class="row">
                <dt>Database</dt>
                <dd class="{{ $database ? 'good' : 'warn' }}">{{ $database ? 'Connected' : 'Unreachable' }}</dd>
            </div>
            <div class="row">
                <dt>Version</dt>
                <dd>{{ $version }}</dd>
            </div>
            <div class="row">
                <dt>Server time (UTC)</dt>
                <dd>{{ $time }}</dd>
            </div>
        </dl>

        <a class="button" href="{{ $healthUrl }}">Open the health check</a>

        <footer>&copy; {{ now()->year }} {{ $brand }}</footer>
    </main>
</body>
</html>
