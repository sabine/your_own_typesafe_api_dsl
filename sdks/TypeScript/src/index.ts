import * as Types from "./generated/types";
import * as Endpoints from "./generated/endpoints";
import { init } from "./config";

const GeneratedApiBindings = {
    ...Types,
    ...Endpoints,
    init,
};

export default GeneratedApiBindings;
