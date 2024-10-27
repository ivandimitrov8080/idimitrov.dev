use std::thread;

use lettre::{message::MultiPart, Message, SmtpTransport, Transport};
use rocket::{form::Form, response::Redirect};
use rocket_governor::{rocket_governor_catcher, Method, Quota, RocketGovernable, RocketGovernor};

#[macro_use]
extern crate rocket;

pub struct RateLimitGuard;

impl<'r> RocketGovernable<'r> for RateLimitGuard {
    fn quota(_method: Method, _route_name: &str) -> Quota {
        Quota::per_hour(Self::nonzero(2 as u32))
    }
}

#[derive(FromForm)]
struct ContactForm<'r> {
    name: &'r str,
    email: &'r str,
    message: &'r str,
}

#[post("/contact", data = "<contact_form>")]
fn contact(
    _limit_guard: RocketGovernor<RateLimitGuard>,
    contact_form: Form<ContactForm<'_>>,
) -> Redirect {
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
    Redirect::to("/contact")
}

#[launch]
fn rocket() -> _ {
    rocket::build()
        .mount("/api", routes![contact])
        .register("/api", catchers![rocket_governor_catcher])
}
