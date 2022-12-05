Editor: https://mermaid.live/

</>Code
sequenceDiagram
    autonumber
    Local OS (startup-script)->>+Remote OS (EC2): Start EC2 instance (AWS CLI)
    Remote OS (EC2)-->>-Local OS (startup-script): Instance state
    loop Ping status
        Local OS (startup-script)->>+Remote OS (EC2): Describe instance (AWS SSM)
        Remote OS (EC2)-->>-Local OS (startup-script): Instance status
        alt Status=Online
            Local OS (startup-script)->>Local OS (startup-script): Launch RDP session
            rect rgb(191, 223, 255)
                Local OS (VS Code)->>+Remote OS (EC2): Start SSH session (AWS SSM)
                Local OS (VS Code)->>+Local OS (VS Code): Code!
                Note right of Local OS (VS Code): Remote development workspace
            end
            opt Kill request
                Local OS (startup-script)->>+Remote OS (EC2): Stop EC2 instance (AWS CLI)
            end
        else
            Local OS (startup-script)->>Local OS (startup-script): Sleep
            Note right of Local OS (startup-script): Instance booting
        end
    end

-Config-
{
  "theme": "base"
}