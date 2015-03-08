(*---------------------------------------------------------------------------
   Copyright 2014 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

(** Result value combinators.

    [Rresult] is a module for handling computation results and errors
    in an explicit and declarative manner without resorting to
    exceptions. It defines a {!result} type and {{!R}combinators}
    to operate on these values.

    Consult {{!usage}usage guidelines} for the type.

    Open the module to use it, this defines only one type and a module
    in your scope. To directly bring the {!R.Infix} operators in scope
    open {!Rresult_infix} instead.

    {e Release %%VERSION%% - %%MAINTAINER%% } *)

(** {1 Results} *)

(** The type for results. *)
type ('a, 'b) result = Ok of 'a | Error of 'b

(** Result value combinators. *)
module R : sig

  (** {1 Results} *)

  type ('a, 'b) t = ('a, 'b) result
  (** The type for results. *)

  val ok : 'a -> ('a, 'b) result
  (** [ok v] is [Ok v]. *)

  val error : 'b -> ('a, 'b) result
  (** [error e] is [Error e]. *)

  val reword_error : ('b -> 'c) -> ('a, 'b) result -> ('a, 'c) result
  (** [reword_error reword r] is:
      {ul
      {- [r] if [r = Ok v]}
      {- [Error (reword e)] if [r = Error e]}} *)

  val get_ok : ('a, 'b) result -> 'a
  (** [get r] is [v] if [r = Ok v] and @raise Invalid_argument otherwise. *)

  val get_error : ('a, 'b) result -> 'b
  (** [get_error r] is [e] if [r = Error e] and @raise Invalid_argument
      otherwise. *)

  val pp :
    pp_ok:(Format.formatter -> 'a -> unit) ->
    pp_error:(Format.formatter -> 'b -> unit) -> Format.formatter ->
    ('a, 'b) result -> unit
  (** [pp pp_ok pp_error ppf r] prints [r] on [ppf] using [pp_ok] and
      [pp_error]. *)

  (**/**)
  val return : 'a -> ('a, 'b) result
  val fail : 'b -> ('a, 'b) result
  (**/**)

  (** {1 Composing results} *)

  val bind : ('a, 'b) result -> ('a -> ('a, 'b) result) -> ('a, 'b) result
  (** [bind r f] is [f v] if [r = Ok v] and [r] if [r = Error _]. *)

  val map : ('a, 'b) result -> ('a -> 'c) -> ('c, 'b) result
  (** [map r f] is [bind r (fun v -> ret (f v))]. *)

  val join : (('a, 'b) result, 'b) result -> ('a, 'b) result
  (** [join r] is [v] if [r = Ok v] and [r] otherwise. *)

  val ( >>= ) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result
  (** [r >>= f] is {!bind}[ r f]. *)

  val ( >>| ) : ('a, 'b) result -> ('a -> 'c) -> ('c, 'b) result
  (** [r >>| f] is {!map}[ r f]. *)

  (** Infix operators.

      Gathers {!R}'s infix operators. *)
  module Infix : sig

   (** {1 Infix operators} *)

    val ( >>= ) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result
    (** [(>>=)] is {!R.( >>= )}. *)

    val ( >>| ) : ('a, 'b) result -> ('a -> 'c) -> ('c, 'b) result
    (** [(>>|)] is {!R.( >>| )}. *)
  end

  (** {1:msgs Error messages} *)

  type msg = [ `Msg of string ]
  (** The type for (error) messages. *)

  val msg : string -> [> msg]
  (** [msg s] is [`Msg s]. *)

  val msgf : ('a, Format.formatter, unit, [> msg]) format4 -> 'a
  (** [msgf fmt ...] formats a message according to [fmt]. *)

  val pp_msg : Format.formatter -> msg -> unit
  (** [pp_msg ppf m] prints [m] on [ppf]. *)

  val error_msg : string -> ('a, [> msg]) result
  (** [error_msg s] is [error (`Msg s)]. *)

  val error_msgf : ('a, Format.formatter, unit, ('b, [> msg]) result)
      format4 -> 'a
  (** [error_msgf fmt ...] is an error message formatted according to [fmt]. *)

  val reword_error_msg : ?replace:bool -> (string -> msg)  ->
    ('a, msg) result -> ('a, [> msg]) result
  (** [reword_error_msg ~replace reword r] is like {!reword_error} except
      if [replace] is [false] (default), the result of [reword old_msg] is
      concatened, on a new line to the old message. *)

  val error_to_msg : pp:(Format.formatter -> 'b -> unit) ->
    ('a, 'b) result -> ('a, [> msg]) result
  (** [error_to_msg pp r] converts errors in [r] with [pp] to an error
      message. *)

  val error_msg_to_invalid_arg : ('a, msg) result -> 'a
  (** [err_msg_to_invalid_arg r] is [v] if [r = Ok v] and

      @raise Invalid_argument with the error message otherwise. *)

  val open_error_msg : ('a, msg) result -> ('a, [> msg]) result
  (** [open_error_msg r] allows to combine a closed error message
      variant with other variants. *)

  (** {1:exn Handling unexpected exceptions}

      {e Getting rid of [null] was not enough}. *)

  type backtrace = [ `Backtrace of Printexc.raw_backtrace ]
  (** The type for exception backtraces. *)

  val pp_backtrace : Format.formatter -> backtrace -> unit
  (** [pp_backtrace ppf bt] prints [bt] on [ppf]. *)

  val trap_exn : ('a -> 'b) -> 'a -> ('b, [> backtrace]) result
  (** [trap_exn f v] is [f v] and traps any exception that may
      occur as an exception backtrace error. *)

  val error_backtrace_to_msg : ('a, backtrace) result -> ('a, [> msg]) result
  (** [error_backtrace_to_msg r] converts exception backtrace errors in
      [r] to an error message. *)

  val open_error_backtrace : ('a, backtrace) result ->
    ('a, [> backtrace]) result
  (** [open_error_backtrace r] allows to combine a closed backtrace error
      variant with other variants. *)

  (** {1:pred Predicates and comparison} *)

  val is_ok : ('a, 'b) result -> bool
  (** [is_ok r] is [true] iff [r = Ok _]. *)

  val is_error : ('a, 'b) result -> bool
  (** [is_error r] is [true] iff [r = Error _]. *)

  val equal : ok:('a -> 'a -> bool) -> error:('b -> 'b -> bool) ->
    ('a, 'b) result -> ('a, 'b) result -> bool
  (** [equal ~ok ~error r r'] tests [r] and [r'] for equality using [ok]
      and [error]. *)

  val compare : ok:('a -> 'a -> int) -> error:('b -> 'b -> int) ->
    ('a, 'b) result -> ('a, 'b) result -> int
  (** [compare ~ok ~error r r'] totally orders [r] and [r'] using [ok]
      and [error]. *)

  (** {1:convert Converting} *)

  val to_option : ('a, 'b) result -> 'a option
  (** [to_option r] is [Some v] if [r = Ok v] and [None] otherwise. *)

  val of_option : none:(unit -> ('a, 'b) result) -> 'a option -> ('a, 'b) result
  (** [of_option ~none r] is [Ok v] if [r = Some v] and [none ()] otherwise. *)

  val to_presult : ('a, 'b) result -> [> `Ok of 'a | `Error of 'b ]
  (** [to_presult r] is [r] as a polymorphic variant result value. *)

  val of_presult : [< `Ok of 'a | `Error of 'b ] -> ('a, 'b) result
  (** [of_presult pr] is [pr] as a result value. *)

  (** {1:ignore Ignoring errors}

      {b Warning.} Using these functions is, most of the time, a bad idea. *)

  val ignore_error : use:'a -> ('a, 'b) result -> 'a
  (** [ignore_error ~use r] is [v] if [r = Ok v] and [use] otherwise. *)

  val kignore_error : use:('a, 'c) result -> ('a, 'b) result -> ('a, 'c) result
  (** [kignore_error ~use r] if [r] if [r = Ok v] and [use] otherwise. *)

  (** {1:type_of_string {!Pervasives} string conversion functions}

      These function return options instead of raising
      exceptions. This allows to easily use them in conjunction with
      {!of_option}. *)

  val bool_of_string : string -> bool option
  (** See {!Pervasives.bool_of_string}. *)

  val int_of_string : string -> int option
  (** See {!Pervasives.int_of_string}. *)

  val nativeint_of_string : string -> nativeint option
  (** See {!Nativeint.of_string}. *)

  val int32_of_string : string -> int32 option
  (** See {!Int32.of_string}. *)

  val int64_of_string : string -> int64 option
  (** See {!Int64.of_string}. *)

  val float_of_string : string -> float option
  (** See {!Pervasives.float_of_string}. *)
end

(** {1:usage Usage design guidelines}

    These are rough design guidelines, don't forget to think.

    {2 Error messages}

    Use {{!R.msgs}error messages} if:
    {ol
    {- Your error messages don't need to be localized, e.g. scripts,
       command line programs.}
    {- The errors don't need to be processed. They are just meant to
       be logged at certain point in your program.}}

    If the above doesn't hold and your errors need to be processed for
    localization or error recovery then use a custom error type in your
    result values.

    {2 Custom error types}

    If your module has specific errors then define an error type, and
    a result type that tags this error type with the library name (or
    any other tag that may make sense, see for example {!R.exn}) along
    with the following functions:

{[
module Mod : sig
  type error = ...
  type 'a result = ('a, [`Mod of error]) Rresult.result
  val pp_error : Format.formatter -> error -> unit
  val open_error : 'a result -> ('a, [> `Mod of error]) Rresult.result
  val error_to_msg : 'a result -> ('a, Rresult.R.msg) Rresult.result

  val f : ... -> 'a result
end
]}

If your library has generic errors that may be useful in other context
or shared among modules and to be composed together, then define your
error type itself as being a variant and return these values
without tagging them.
{[
module Mod : sig
  type error = [`Generic of ... | ... ]
  type 'a result = ('a, error) Rresult.result
  val pp_error : Format.formatter -> error -> unit
  val open_error : 'a result -> ('a, [> error]) Rresult.result
  val error_to_msg : 'a result -> ('a, Rresult.R.msg) Rresult.result

  val f : ... -> 'a result
end
]}
In the latter case it may still be useful to provide a function to
tag these errors whenever they reach a certain point of the program.
For this the following function could be added to [Mod]:
{[
val pack_error : 'a result ->  ('a, [> `Mod of error]) Rresult.result
]}
*)

(*---------------------------------------------------------------------------
   Copyright 2014 Daniel C. Bünzli.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

   3. Neither the name of Daniel C. Bünzli nor the names of
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  ---------------------------------------------------------------------------*)
