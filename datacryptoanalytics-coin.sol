// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.5.99 <0.8.0;

contract DTACoin {
    // A palavra-chave "public" cria variáveis
    // acessível a partir de outros contratos
    address public minter;
    mapping (address => uint) public balances;

    // Os eventos permitem que os clientes reajam a determinados
    // mudanças de contrato que você declara
    event Sent(address from, address to, uint amount);

    // O código do construtor só é executado quando o contrato
    // é criado
    constructor() {
        minter = msg.sender;
    }

    // Envia uma quantidade de moedas recém-criadas para um endereço
    // Só pode ser chamado pelo criador do contrato
    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        require(amount < 1e60);
        balances[receiver] += amount;
    }

    // Envia uma quantidade de moedas existentes
    // de qualquer chamador para um endereço
    function send(address receiver, uint amount) public {
        require(amount <= balances[msg.sender], "Insufficient balance.");
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
}
