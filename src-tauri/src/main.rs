// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::api::process::{Command, CommandEvent};

// Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

fn main() {
    if let Err(e) = fix_path_env::fix() {
        println!("{}", e);
    } else {
        println!("PATH: {}", std::env::var("PATH").unwrap());
    }
    tauri::Builder::default()
        .setup(|_app| {
            println!("phoenix server starting...");
            start_server();
            check_server_started();
            println!("phoenix server started.");
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![greet])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

fn start_server() {
    tauri::async_runtime::spawn(async move {
        let (mut rx, mut _child) = Command::new_sidecar("server")
            .expect("failed to setup `app` sidecar")
            .spawn()
            .expect("Failed to spawn packaged node");

        while let Some(event) = rx.recv().await {
            if let CommandEvent::Stdout(line) = event {
                println!("{}", line);
            }
        }
    });
}

fn check_server_started() {
    let sleep_interval = std::time::Duration::from_secs(1);
    let host = std::env::var("PHX_HOST").unwrap_or("localhost".to_string());
    let port = std::env::var("PORT").unwrap_or("4000".to_string());
    let addr = format!("{}:{}", host, port);
    println!("Waiting for your phoenix dev server to start on {}...", addr);
    loop {
        if std::net::TcpStream::connect(addr.clone()).is_ok() {
            break;
        }
        std::thread::sleep(sleep_interval);
    }
}
