import Foundation

/// Notification service for multi-channel output
/// Supports Discord, Telegram, Email, and SMS
struct NotificationService {
    
    // MARK: - Configuration
    
    struct Config {
        var discordWebhook: String?
        var telegramChatId: String?
        var telegramBotToken: String?
        var emailRecipient: String?
        var pushoverUserKey: String?
        var pushoverApiToken: String?
    }
    
    // MARK: - Discord
    
    /// Send message to Discord via webhook
    static func sendDiscord(webhookUrl: String, message: String, images: [Data]? = nil) async throws {
        var request = URLRequest(url: URL(string: webhookUrl)!)
        request.httpMethod = "POST"
        
        // Discord webhooks support embeds
        let payload: [String: Any] = [
            "content": message
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NotificationError.discordFailed
        }
    }
    
    // MARK: - Telegram
    
    /// Send message via Telegram bot
    /// Get chat_id by messaging @BotFather to create a bot, then message the bot
    static func sendTelegram(botToken: String, chatId: String, message: String, images: [Data]? = nil) async throws {
        // If images provided, send as photo
        if let images = images, !images.isEmpty {
            for imageData in images {
                let boundary = UUID().uuidString
                var request = URLRequest(url: URL(string: "https://api.telegram.org/bot\(botToken)/sendPhoto")!)
                request.httpMethod = "POST"
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                var body = Data()
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n\(chatId)\r\n".data(using: .utf8)!)
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
                
                request.httpBody = body
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw NotificationError.telegramFailed
                }
            }
        } else {
            // Send text message
            let urlString = "https://api.telegram.org/bot\(botToken)/sendMessage"
            var request = URLRequest(url: URL(string: urlString)!)
            request.httpMethod = "POST"
            
            let payload: [String: Any] = [
                "chat_id": chatId,
                "text": message,
                "parse_mode": "Markdown"
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NotificationError.telegramFailed
            }
        }
    }
    
    // MARK: - Email (via local Mail app)
    
    /// Send email using system Mail compose
    /// Note: This requires user interaction - opens Mail.app
    static func sendEmail(to: String, subject: String, body: String, attachments: [URL]? = nil) async throws {
        // For macOS, we'll use AppleScript to send via Mail
        let script = """
        tell application "Mail"
            set newMessage to make new outgoing message with properties {subject:"\(subject)", content:"\(body)"}
            tell newMessage
                make new to recipient with properties {address:"\(to)"}
                \(attachments?.map { "make new attachment with properties {file name:\"\($0.path)\"}" }.joined(separator: "\n") ?? "")
            end tell
            send newMessage
        end tell
        """
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        
        try task.run()
        task.waitUntilExit()
        
        guard task.terminationStatus == 0 else {
            throw NotificationError.emailFailed
        }
    }
    
    // MARK: - Pushover
    
    /// Send Pushover notification
    static func sendPushover(userKey: String, apiToken: String, message: String, title: String? = nil, images: [Data]? = nil) async throws {
        var request = URLRequest(url: URL(string: "https://api.pushover.net/1/messages.json")!)
        request.httpMethod = "POST"
        
        var payload: [String: Any] = [
            "token": apiToken,
            "user": userKey,
            "message": message
        ]
        
        if let title = title {
            payload["title"] = title
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NotificationError.pushoverFailed
        }
    }
    
    // MARK: - System Notification
    
    /// Send macOS system notification
    static func sendSystemNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Errors

enum NotificationError: Error, LocalizedError {
    case discordFailed
    case telegramFailed
    case emailFailed
    case pushoverFailed
    case notConfigured
    
    var errorDescription: String? {
        switch self {
        case .discordFailed: return "Failed to send Discord message"
        case .telegramFailed: return "Failed to send Telegram message"
        case .emailFailed: return "Failed to send email"
        case .pushoverFailed: return "Failed to send Pushover notification"
        case .notConfigured: return "Notification channel not configured"
        }
    }
}

// MARK: - Import for UserNotifications

import UserNotifications