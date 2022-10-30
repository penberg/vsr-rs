use crate::message::Message;
use crate::types::{ClientID, RequestNumber};
use crossbeam_channel::Sender;
use log::trace;
use std::fmt::Debug;
use std::sync::Mutex;

pub type ClientCallback = fn(RequestNumber);

/// Client.
pub struct Client<Op>
where
    Op: Clone + Debug + Send + Sync,
{
    pub client_id: ClientID,
    pub view_number: usize,
    pub nr_replicas: usize,
    pub message_bus: Sender<(usize, Message<Op>)>,
    inner: Mutex<ClientInner>,
}

struct ClientInner {
    request_number: RequestNumber,
    callbacks: Option<(RequestNumber, ClientCallback)>,
}

impl<Op> Client<Op>
where
    Op: Clone + Debug + Send + Sync,
{
    pub fn new(nr_replicas: usize, message_bus: Sender<(usize, Message<Op>)>) -> Client<Op> {
        let request_number = 0;
        let callbacks = None;
        let inner = ClientInner {
            request_number,
            callbacks,
        };
        let inner = Mutex::new(inner);
        Client {
            client_id: 0,
            view_number: 0,
            nr_replicas,
            message_bus,
            inner,
        }
    }

    pub fn request(&self, op: Op, callback: ClientCallback) {
        trace!("Client {} <- {:?}", self.client_id, op);
        let primary_id = self.view_number % self.nr_replicas;
        let mut inner = self.inner.lock().unwrap();
        let request_number = inner.request_number;
        inner.request_number += 1;
        inner.callbacks.replace((request_number, callback));
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

    pub fn on_message(&self) {
        let mut inner = self.inner.lock().unwrap();
        if let Some((request_number, callback)) = inner.callbacks.take() {
            callback(request_number);
        }
    }
}
