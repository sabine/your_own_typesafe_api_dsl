import GeneratedApiBindings from "./bindings/TypeScript/src";

async function lookup_user(user_id: string) {
    let response = await GeneratedApiBindings.get_user(user_id);

    if ("error" in response) {
        //do something
        return
    }

    switch (response.data.user[0]) {
        case "UserMember":
            response.data.user[1].display_name
    } 
}