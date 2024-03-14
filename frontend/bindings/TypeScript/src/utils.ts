import { API_KEY, API_URL, fetch } from "./config";

export type ApiResponse<S> =
  { data: S }
| {error: true; status: number; data?: { message: string}};

function api_fetch(url: string, opts: any): Promise<ApiResponse<any>> {
    let fetch_url = API_URL + url;
    console.log(['fetch_url', fetch_url]);
    const response = fetch(fetch_url, opts).then(async (res: Response) => {
        console.log(res);

        switch (res.status) {
            case 200:
                return res.json().then((data) => {
                    let d = {
                        data
                    };
                    console.log("d", d);
                    return d;
                });
            default:
                return res.json().then((data) => {
                    return {
                        error: true,
                        status: res.status,
                        data
                    };
                });
        }
    });

    return response;
}

type ApiHeaders = {
    Accept: string;
    'Content-Type'?: string;
    'X-Access-Token'?: string;
};

export function get(url: string) {
    let headers: ApiHeaders = {
        Accept: 'application/json',
        'Content-Type': 'application/json'
    };
    if (!API_KEY) throw "api_key is not set via init({.., api_key: YOUR_API_KEY})";
    headers['X-Access-Token'] = API_KEY;
    return api_fetch(url, {
        headers
    });
}

export function post(url: string, body?: any) {
    let b = body ? JSON.stringify(body) : 'null';
    let headers: ApiHeaders = {
        Accept: 'application/json',
        'Content-Type': 'application/json'
    };
    if (!API_KEY) throw "api_key is not set via init({.., api_key: YOUR_API_KEY})";
    headers['X-Access-Token'] = API_KEY;
    return api_fetch(url, {
        method: 'POST',
        body: b,
        headers
    });
}

export function del(url: string) {
    let headers: ApiHeaders = {
        Accept: 'application/json',
        'Content-Type': 'application/json'
    };
    if (!API_KEY) throw "api_key is not set via init({.., api_key: YOUR_API_KEY})";
    headers['X-Access-Token'] = API_KEY;
    return api_fetch(url, {
        method: 'DELETE',
        headers
    });
}

export async function postFormData(
    url: string,
    formData: FormData
) {
    let headers: ApiHeaders = {
        Accept: 'application/json'
    };
    if (!API_KEY) throw "api_key is not set via Chattelite.init({.., api_key: YOUR_API_KEY})";
    headers['X-Access-Token'] = API_KEY;

    return api_fetch(url, {
        method: 'POST',
        body: formData,
        headers
    });
}

function url_encode_add_key_value_pair(
    result: [string, string][],
    name: string,
    value: string
): void {
    if (value === undefined || value === null) return;
    result.push([encodeURIComponent(name), encodeURIComponent(value)]);
}

interface QueryParamsInterface {
    params: { [key: string]: string | number | boolean | QueryParamsInterface };
    url_encode(): [string, string][];
}

class GenericQueryParams implements QueryParamsInterface {
    params: { [key: string]: string | number | boolean | QueryParamsInterface };

    constructor(s: { [key: string]: string | number | boolean | QueryParamsInterface }) {
        this.params = s;
    }

    url_encode(): [string, string][] {
        let result: [string, string][] = [];
        for (let key in this.params) {
            let o = this.params[key];
            if (o === null) continue;
            if (typeof o === 'string' || typeof o === 'number' || typeof o === 'boolean') {
                url_encode_add_key_value_pair(result, key, o.toString());
                continue;
            }
            if (Array.isArray(o)) {
                if (o.length > 0) {
                    if (
                        typeof o[0] === 'string' ||
                        typeof o[0] === 'number' ||
                        typeof o[0] === 'boolean'
                    ) {
                        url_encode_add_key_value_pair(result, key, o.join(','));
                        continue;
                    }
                }
                throw 'url_encode not implemented for ' + typeof o + ' ' + JSON.stringify(o);
            }
            if (typeof o === 'object' && o.hasOwnProperty('url_encode')) {
                for (let [k, v] of o.url_encode()) {
                    result.push([`${key}.${k}`, v]);
                }
            }
            throw 'url_encode not implemented for ' + typeof o + ' ' + JSON.stringify(o);
        }

        return result;
    }
}

export function stringify_query(q: any): string {
    let result = new GenericQueryParams(q).url_encode();
    console.log(['stringify_query', result]);
    return result.length > 0 ? `?${result.map(([k, v]) => `${k}=${v}`).join('&')}` : '';
}

export default {
    get: get,
    post: post,
    postFormData: postFormData
};
