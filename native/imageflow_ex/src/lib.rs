extern crate imageflow_types;

mod job;

mod atoms {
    rustler::atoms! {
        // success
        output_file_saved,
        input_file_added,
        input_buffer_added,
        output_buffer_added,
        output_file_added,
        job_destroyed,
        // error
        create_job_error,
        add_input_buffer_error,
        add_input_file_error,
        add_output_buffer_error,
        failed_saving_output_to_file,
        failed_destroying_job,
        failed_loading_job_from_id,
        failed_adding_input_buffer,
        failed_adding_input_file,
        failed_getting_output_buffer,
        failed_adding_output_buffer,
        failed_sending_message_to_job
    }
}

use job::Job;
use rustler::{Atom, Binary};

rustler::init!(
    "Elixir.Imageflow.NIF",
    [
        get_long_version_string,
        job_create,
        job_destroy,
        job_add_input_buffer,
        job_add_input_file,
        job_add_output_buffer,
        job_get_output_buffer,
        job_save_output_to_file,
        job_message,
    ]
);

macro_rules! job {
    ($id:expr) => {
        match Job::load_from_id($id) {
            Ok(job) => Ok(job),
            Err(err) => {
                log::error!("Erro getting job by id, reason={:?}", err);
                Err(atoms::failed_loading_job_from_id())
            }
        }
    };
}

#[rustler::nif]
fn get_long_version_string() -> String {
    imageflow_types::version::one_line_version()
}

#[rustler::nif]
pub fn job_create() -> Result<usize, Atom> {
    match Job::create() {
        Ok(id) => Ok(id),
        Err(e) => {
            println!("Failed creating job, reason={:?}", e);
            Err(atoms::create_job_error())
        }
    }
}

#[rustler::nif]
pub fn job_destroy(id: usize) -> Result<Atom, Atom> {
    match Job::destroy_from_id(id) {
        Ok(_) => Ok(atoms::job_destroyed()),
        Err(_) => Err(atoms::failed_destroying_job()),
    }
}

#[rustler::nif]
pub fn job_add_input_buffer(id: usize, io_id: i32, bytes: Binary) -> Result<Atom, Atom> {
    match job!(id)?.add_input_buffer(io_id, bytes.as_slice()) {
        Ok(_) => Ok(atoms::input_buffer_added()),
        Err(reason) => {
            println!("Error adding input buffer, reason={:?}", reason);
            Err(atoms::failed_adding_input_buffer())
        }
    }
}

#[rustler::nif]
pub fn job_add_input_file(id: usize, io_id: i32, path: String) -> Result<Atom, Atom> {
    match job!(id)?.add_input_file(io_id, &path) {
        Ok(_) => Ok(atoms::input_file_added()),
        Err(e) => {
            println!("Failed adding input file, reason={:?}", e);
            Err(atoms::failed_adding_input_file())
        }
    }
}

#[rustler::nif]
pub fn job_get_output_buffer(id: usize, io_id: i32) -> Result<Vec<u8>, Atom> {
    job!(id)?.get_output_buffer(io_id).map_err(|err| {
        println!("Failed to get output buffer, reason={:?}", err);
        atoms::failed_getting_output_buffer()
    })
}

#[rustler::nif]
pub fn job_add_output_buffer(id: usize, io_id: i32) -> Result<Atom, Atom> {
    match job!(id)?.add_output_buffer(io_id) {
        Ok(_) => Ok(atoms::output_buffer_added()),
        Err(err) => {
            println!("Failed to adding output buffer, reason={:?}", err);
            Err(atoms::failed_adding_output_buffer())
        }
    }
}

#[rustler::nif]
pub fn job_save_output_to_file(id: usize, io_id: i32, path: String) -> Result<Atom, Atom> {
    match job!(id)?.save_output_to_file(io_id, &path) {
        Ok(_) => Ok(atoms::output_file_saved()),
        Err(reason) => {
            println!("Error saving output to file, reason={:?}", reason);
            Err(atoms::failed_saving_output_to_file())
        }
    }
}

#[rustler::nif]
pub fn job_message(id: usize, method: String, message: String) -> Result<String, Atom> {
    match job!(id)?.message(&method, &message) {
        Ok(resp) => Ok(String::from_utf8_lossy(&resp.response_json).to_string()),
        Err(msg) => {
            println!("Failed sending message to job, reason={:?}", msg);
            Err(atoms::failed_sending_message_to_job())
        }
    }
}
