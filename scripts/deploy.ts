import { buf2hex } from "@taquito/utils";
import { InMemorySigner } from "@taquito/signer";
import { MichelsonMap, TezosToolkit } from "@taquito/taquito";
import code_contract_1 from "../src/compiled/contract_1.json";
import code_contract_2 from "../src/compiled/contract_2.json";
import dotenv from "dotenv";
import metadata from "./metadata/main.json";
import path from "path";
// Read environment variables from .env file
dotenv.config({ path: path.join(__dirname, "..", ".env") });

// Initialize RPC connection
const Tezos = new TezosToolkit(process.env.NODE_URL || "");

(async () => {
    const signer = await InMemorySigner.fromSecretKey(
        process.env.ADMIN_SK || ""
    );
    const admin: string = await signer.publicKeyHash();
    Tezos.setProvider({ signer });

    async function deploy_contract_1() {
        const storage = {
            user_map: new MichelsonMap(),
            user_blacklist: [],
            admin_list: new MichelsonMap(),
            has_paid: new MichelsonMap(),
        };
        const op = await Tezos.contract.originate({
            code: code_contract_1,
            storage: storage,
        });
        await op.confirmation();
        console.log(`[OK] Contract 1: ${op.contractAddress}`);
        // check contract storage with CLI
        console.log(
            `tezos-client --endpoint http://localhost:20000 get contract storage for ${op.contractAddress}`
        );
    }

    async function deploy_contract_2() {
        const storage = {
            admin: await signer.publicKeyHash(),
            tezos_price: new MichelsonMap(),
        };
        const op = await Tezos.contract.originate({
            code: code_contract_2,
            storage: storage,
        });
        await op.confirmation();
        console.log(`[OK] Contract 2: ${op.contractAddress}`);
        // check contract storage with CLI
        console.log(
            `tezos-client --endpoint http://localhost:20000 get contract storage for ${op.contractAddress}`
        );

        const request = await fetch(
            "https://api.coingecko.com/api/v3/simple/price?ids=tezos&vs_currencies=usd"
        );
        const body: {
            tezos: {
                usd: string;
            };
        } = await request.json();
        const now = new Date();
        const priceMul = Math.round(parseFloat(body.tezos.usd) * 1000);
        const contract = await Tezos.contract.at(op.contractAddress);
        await contract.methods
            .addPrice(now.getTime().toString(), priceMul)
            .send();
    }
    await deploy_contract_1();
    await deploy_contract_2();
})();
