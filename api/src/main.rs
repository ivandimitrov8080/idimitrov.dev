use lettre::{Message, SmtpTransport, Transport};
use rocket::{form::Form, response::Redirect};

#[macro_use]
extern crate rocket;

#[derive(FromForm)]
struct ContactForm<'r> {
    name: &'r str,
    email: &'r str,
    message: &'r str,
}

#[post("/contact", data = "<contact_form>")]
fn contact(contact_form: Form<ContactForm<'_>>) -> Redirect {
    let name = contact_form.name;
    let email = contact_form.email;
    let message = contact_form.message;
    let email = Message::builder()
        .from(format!("{name} <{email}>").parse().unwrap())
        .to("Ivan Kirilov Dimitrov <ivan@idimitrov.dev>"
            .parse()
            .unwrap())
        .subject("Website contact form!")
        .body(String::from(message))
        .unwrap();
    let sender = SmtpTransport::unencrypted_localhost();
    let result = sender.send(&email);
    println!("{:?}", result);
    Redirect::to("/contact")
}

#[launch]
fn rocket() -> _ {
    rocket::build().mount("/api", routes![contact])
}
