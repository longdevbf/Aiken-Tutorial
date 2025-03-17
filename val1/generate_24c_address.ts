import {Lucid} from "https://deno.land/x/lucid@0.10.10/mod.ts";
//this is import lucid from denoland lucid to project
const lucid = await Lucid.new(undefined, "Preview");
//impress object Lucid in environment Preview
const privateKey = lucid.utils.generatePrivateKey();
await Deno.writeTextFile("me.sk", privateKey);
//generate 24 character random in file me.sk (dont need go to wallet)
const address = lucid.selectWalletFromPrivateKey(privateKey)
    .wallet.address();
await Deno.writeTextFile("me.addr", address);
//use PrivateKey's address and write address to me.addr
//next step :  run file : deno run --allow-net --allow-write file.ts

