-module(erlang_oauth_2legged_resource).

-export([
         init/1, 
         malformed_request/2, 
         is_authorized/2, 
         content_types_provided/2, 
         to_text/2
        ]).

-include_lib("webmachine/include/webmachine.hrl").

-define(REALM, "http://localhost:8000").

-record(state, {
          params
         }).


init([]) ->
    {ok, #state{}}.


malformed_request(ReqData, State) ->
    Params = wrq:req_qs(ReqData),
    case oauth_utils:check_params(Params) of
        ok             -> {false, ReqData, State#state{params=Params}};
        {error, Error} -> malformed(Error, ReqData, State)
    end.


malformed(Body, ReqData, State) ->
    {true, wrq:set_resp_header("Content-Type", "text/plain", wrq:set_resp_body(Body, ReqData)), State}.


is_authorized(ReqData, State=#state{params=Params}) ->
    Path = wrq:path(ReqData),
    case oauth_utils:verify(Params, ?REALM, Path, fun consumer_lookup/1) of
        ok             -> {true, ReqData, State};
        {error, Error} -> unauthorized(Error, ReqData, State)
    end.


unauthorized(Body, ReqData, State) ->
    {"OAuth realm=\"" ?REALM "\"", wrq:set_resp_header("Content-Type", "text/plain", wrq:set_resp_body(Body, ReqData)), State}.


content_types_provided(ReqData, State) ->
    {[{"text/plain", to_text}], ReqData, State}.


to_text(ReqData, State) ->
    {"hello world", ReqData, State}.


consumer_lookup("key") -> {ok, "secret"};
consumer_lookup(_) -> {error, not_found}.
