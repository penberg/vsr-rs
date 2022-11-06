use crate::config::Config;
use crate::message::Message;
use crate::types::{ClientID, ReplicaID, RequestNumber, ViewNumber};
use crossbeam_channel::Sender;
use log::trace;
use parking_lot::{Condvar, Mutex};
use std::fmt::Debug;
use std::sync::Arc;

pub type ClientCallback = Box<dyn Fn(RequestNumber) + Send>;

/// Client.
pub struct Client<Op>
where
    Op: Clone + Debug + Send,
{
    config: Arc<Mutex<Config>>,
    client_id: ClientID,
    view_number: ViewNumber,
    replica_tx: Sender<(ReplicaID, Message<Op>)>,
    inner: Mutex<ClientInner>,
}

struct ClientInner {
    request_number: RequestNumber,
    callbacks: Option<(RequestNumber, ClientCallback)>,
}

impl<Op> Client<Op>
where
    Op: Clone + Debug + Send,
{
    pub fn new(
        config: Arc<Mutex<Config>>,
        replica_tx: Sender<(ReplicaID, Message<Op>)>,
    ) -> Client<Op> {
        let request_number = 0;
        let callbacks = None;
        let inner = ClientInner {
            request_number,
            callbacks,
        };
        let inner = Mutex::new(inner);
        Client {
            config,
            client_id: 0,
            view_number: 0,
            replica_tx,
            inner,
        }
    }

    pub fn request(&self, op: Op) -> RequestNumber {
        let pair = Arc::new((Mutex::new(None), Condvar::new()));
        let pair_ = Arc::clone(&pair);
        let callback = move |request_number| {
            let (lock, cvar) = &*pair_;
            let mut completed = lock.lock();
            *completed = Some(request_number);
            cvar.notify_one();
        };
        self.request_async(op, Box::new(callback));
        let (lock, cvar) = &*pair;
        let mut completed = lock.lock();
        loop {
            if let Some(request_number) = *completed {
                return request_number;
            }
            cvar.wait(&mut completed);
        }
    }

    pub fn request_async(&self, op: Op, callback: ClientCallback) {
        trace!("Client {} <- {:?}", self.client_id, op);
        let primary_id = self.config.lock().primary_id(self.view_number);
        let mut inner = self.inner.lock();
        let request_number = inner.request_number;
        inner.request_number += 1;
        inner.callbacks.replace((request_number, callback));
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
        let mut inner = self.inner.lock();
        if let Some((request_number, callback)) = inner.callbacks.take() {
            callback(request_number);
        }
    }
}
