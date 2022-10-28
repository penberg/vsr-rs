use crate::message::Message;
use crate::types::{ClientID, RequestNumber};
use log::trace;
use std::fmt::Debug;
use std::sync::mpsc::Sender;

pub type ClientCallback = fn(RequestNumber);

/// Client.
pub struct Client<Operation>
where
    Operation: Clone + Debug + Send,
{
    pub client_id: ClientID,
    pub request_number: RequestNumber,
    pub view_number: usize,
    pub nr_replicas: usize,
    pub message_bus: Sender<(usize, Message<Operation>)>,
    pub callbacks: Option<(RequestNumber, ClientCallback)>,
}

impl<Op> Client<Op>
where
    Op: Clone + Debug + Send,
{
    pub fn new(nr_replicas: usize, message_bus: Sender<(usize, Message<Op>)>) -> Client<Op> {
        let callbacks = None;
        Client {
            client_id: 0,
            request_number: 0,
            view_number: 0,
            nr_replicas,
            message_bus,
            callbacks,
        }
    }

    pub fn request(&mut self, op: Op, callback: ClientCallback) {
        trace!("Client {} <- {:?}", self.client_id, op);
        let primary_id = self.view_number % self.nr_replicas;
        let request_number = self.request_number;
        self.request_number += 1;
        self.callbacks.replace((request_number, callback));
        self.message_bus
            .send((
                primary_id,
                Message::Request {
                    client_id: self.client_id,
                    request_number,
                    op,
                },
            ))
            .unwrap();
    }

    pub fn on_message(&mut self) {
        if let Some((request_number, callback)) = self.callbacks.take() {
            callback(request_number);
        }
    }
}
