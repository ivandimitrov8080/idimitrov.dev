use lettre::{Message, SmtpTransport, Transport};
use rocket::response::Redirect;

#[macro_use]
extern crate rocket;

#[post("/api/contact")]
fn contact() -> Redirect {
    let email = Message::builder()
        .from("Website <noreply@idimitrov.dev>".parse().unwrap())
        .reply_to("Website <noreply@idimitrov.dev>".parse().unwrap())
        .to("Ivan Kirilov Dimitrov <ivan@idimitrov.dev>"
            .parse()
            .unwrap())
        .subject("Happy new year")
        .body(String::from("Be happy!"))
        .unwrap();
    let sender = SmtpTransport::relay("127.0.0.1").unwrap().build();
    let result = sender.send(&email);
    println!("{:?}", result);
    Redirect::to("/")
}

#[launch]
fn rocket() -> _ {
    rocket::build().mount("/", routes![contact])
}
