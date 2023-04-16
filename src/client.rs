use crate::config::Config;
use crate::message::Message;
use crate::types::{ClientID, ReplicaID, RequestNumber, ViewNumber};
use crossbeam_channel::Sender;
use log::trace;
use std::cell::RefCell;
use std::fmt::Debug;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;

pub type ClientCallback = Box<dyn Fn(RequestNumber) + Send>;

/// Client.
pub struct Client<Op>
where
    Op: Clone + Debug + Send,
{
    config: Arc<Config>,
    client_id: ClientID,
    view_number: ViewNumber,
    replica_tx: Sender<(ReplicaID, Message<Op>)>,
    request_number: AtomicUsize,
    callbacks: RefCell<Option<(RequestNumber, ClientCallback)>>,
}

impl<Op> Client<Op>
where
    Op: Clone + Debug + Send,
{
    pub fn new(config: Arc<Config>, replica_tx: Sender<(ReplicaID, Message<Op>)>) -> Client<Op> {
        let request_number = AtomicUsize::new(0);
        let callbacks = RefCell::new(None);
        Client {
            config,
            client_id: 0,
            view_number: 0,
            replica_tx,
            request_number,
            callbacks,
        }
    }

    pub fn on_request(&self, op: Op, callback: ClientCallback) {
        trace!("Client {} <- {:?}", self.client_id, op);
        let primary_id = self.config.primary_id(self.view_number);
        let request_number = self.request_number.fetch_add(1, Ordering::SeqCst);
        self.callbacks.replace(Some((request_number, callback)));
        self.replica_tx
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
        let mut callbacks = self.callbacks.borrow_mut();
        if let Some((request_number, callback)) = callbacks.take() {
            callback(request_number);
        }
    }
}
