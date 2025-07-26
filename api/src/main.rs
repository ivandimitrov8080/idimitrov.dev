use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::Mutex;
use std::thread;

use ::captcha::{gen, Difficulty};
use lettre::{message::MultiPart, Message, SmtpTransport, Transport};
use rocket::State;
use rocket::{form::Form, response::Redirect};
use rocket_governor::{rocket_governor_catcher, Method, Quota, RocketGovernable, RocketGovernor};

#[macro_use]
extern crate rocket;

pub struct MemoryDb {
    captcha: Mutex<HashMap<String, String>>,
}

pub struct RateLimitGuard;

impl<'r> RocketGovernable<'r> for RateLimitGuard {
    fn quota(_method: Method, _route_name: &str) -> Quota {
        Quota::per_minute(Self::nonzero(5u32))
    }
}

#[derive(FromForm)]
struct ContactForm<'r> {
    name: &'r str,
    email: &'r str,
    message: &'r str,
    captcha: &'r str,
}

#[get("/captcha")]
fn captcha(mdb: &State<MemoryDb>, remote_addr: SocketAddr) -> Vec<u8> {
    let captcha = gen(Difficulty::Medium).as_tuple().unwrap();
    mdb.captcha
        .lock()
        .unwrap()
        .insert(remote_addr.ip().to_string(), captcha.0);
    captcha.1
}

#[post("/contact", data = "<contact_form>")]
fn contact(
    _limit_guard: RocketGovernor<RateLimitGuard>,
    contact_form: Form<ContactForm<'_>>,
    mdb: &State<MemoryDb>,
    remote_addr: SocketAddr,
) -> Redirect {
    let mut capdb = mdb.captcha.lock().unwrap();
    let ip = remote_addr.ip().to_string();
    let is_captcha_valid = capdb.contains_key(&ip)
        && capdb
            .remove(&ip)
            .unwrap()
            .eq(&contact_form.captcha.to_string());
    match is_captcha_valid {
        true => {
            send_email(contact_form);
            Redirect::to("/contact")
        }
        false => Redirect::to("/404"),
    }
}

fn send_email(contact_form: Form<ContactForm<'_>>) {
    let name = contact_form.name;
    let email = contact_form.email;
    let message = contact_form.message;
    let email = Message::builder()
        .from(format!("{name} <{email}>").parse().unwrap())
        .to("Ivan Kirilov Dimitrov <ivan@idimitrov.dev>"
            .parse()
            .unwrap())
        .subject("Website contact form!")
        .multipart(MultiPart::alternative_plain_html(
            String::from(message),
            String::from(message),
        ))
        .unwrap();
    let sender = SmtpTransport::unencrypted_localhost();
    thread::spawn(move || {
        let result = sender.send(&email);
        println!("{:?}", result);
    });
}

#[launch]
fn rocket() -> _ {
    rocket::build()
        .manage(MemoryDb {
            captcha: Mutex::new(HashMap::new()),
        })
        .mount("/api", routes![contact, captcha])
        .register("/api", catchers![rocket_governor_catcher])
}
