open Import

type 'a t =
  { key : string
  ; toJson : 'a -> Js.Json.t
  ; ofJson : Js.Json.t -> 'a
  ; scope : WorkspaceConfiguration.configurationTarget
  }

let create ~scope ~key ~ofJson ~toJson = { scope; key; toJson; ofJson }

let get ?section t =
  let section = Workspace.getConfiguration ?section () in
  match WorkspaceConfiguration.get section t.key with
  | None -> None
  | Some v -> (
    match t.ofJson v with
    | s -> Some s
    | exception Json.Decode.DecodeError msg ->
      message `Error "Setting %s is invalid: %s" t.key msg;
      None )

let set ?section t v =
  let section = Workspace.getConfiguration ?section () in
  match Vscode.Workspace.name () with
  | None -> Promise.return ()
  | Some _ ->
    let scope = WorkspaceConfiguration.configurationTargetToJs t.scope in
    WorkspaceConfiguration.update section t.key (t.toJson v) scope

let string =
  let toJson = Js.Json.string in
  let ofJson (y : Js.Json.t) = Json.Decode.string y in
  create ~ofJson ~toJson
