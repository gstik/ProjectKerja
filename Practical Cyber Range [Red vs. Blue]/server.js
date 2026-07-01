const express = require('express');
const cookieParser = require('cookie-parser');
const app = express();

app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// PHASE 1: Reconnaissance
// Expose backend technology in headers
app.use((req, res, next) => {
    res.setHeader('X-Powered-By', 'SCENARIO75{Node.js}');
    next();
});

// Serve robots.txt with hidden paths
app.get('/robots.txt', (req, res) => {
    res.type('text/plain');
    res.send("User-agent: *\nDisallow: /api/verify-mfa # SCENARIO75{/api/verify-mfa}\nDisallow: /dashboard # SCENARIO75{/dashboard}");
});

// Initial endpoint issuing the pre-MFA session
app.get('/', (req, res) => {
    // Explicitly set HttpOnly to false (SCENARIO75{False})
    res.cookie('pre_mfa_session', 'pending_mfa_verification', { httpOnly: false });
    
    // ASCII art source code clue (SCENARIO75{robots.txt})
    res.send(`
        <html>
        <body>
            <h1>Admin Feedback System</h1>
            <p>Session ID: SCENARIO75{pre_mfa_session} / Status: SCENARIO75{pending_mfa_verification}</p>
            <form action="/feedback" method="POST"> <textarea name="feedback" rows="5" cols="40" placeholder="Submit your feedback here..."></textarea><br/>
                <button type="submit">Submit Feedback</button>
            </form>
        </body>
        </html>
    `);
});

// PHASE 2: Defense Evasion (WAF & XSS)
app.post('/feedback', (req, res) => {
    const payload = req.body.feedback || "";
    
    // Rudimentary WAF: Block standard script tags
    if (payload.toLowerCase().includes('<script>')) {
        return res.status(403).send("WAF BLOCKED: Malicious input detected. SCENARIO75{403}");
    }

    // Checking for WAF Bypass conditions (svg, fetch, obfuscated cookie)
    if (payload.includes('<svg>') && payload.includes("window['docu'+'ment']['coo'+'kie']") && payload.includes('fetch')) {
        // SCENARIO75{<svg>}, SCENARIO75{window['docu'+'ment']['coo'+'kie']}, SCENARIO75{fetch}
        app.locals.storedXss = payload;
        return res.send("Feedback submitted. An admin will review it shortly.");
    }
    
    res.send("Feedback received.");
});

// PHASE 3: Initial Access (MFA Bypass & Session Replay)
app.get('/dashboard', (req, res) => {
    const cookies = req.headers.cookie || "";
    
    // Check for the authenticated administrative session prefix
    if (cookies.includes('adm_sess=')) { // SCENARIO75{adm_sess}
        // Completely skip /api/verify-mfa
        res.send(`
            <html>
            <body>
                <h1>Admin Dashboard (MFA Bypassed)</h1>
                <p>Welcome, Administrator.</p>
                <div class="xss-payload"> ${app.locals.storedXss || ""}
                </div>
                <hr/>
                <h2>Final Red Team Flag:</h2>
                <p>SCENARIO75{RED_C00k13_MFA_Byp4ss_0wn3d}</p>
            </body>
            </html>
        `);
    } else {
        res.status(401).send("Unauthorized. Valid admin cookie required. Verify MFA at SCENARIO75{/api/verify-mfa}");
    }
});

app.listen(3075, () => {
    console.log('Vulnerable Web App running on port 3075');
}); 