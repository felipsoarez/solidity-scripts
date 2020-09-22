// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.6.99 <0.8.0;

/// @Título Votação com delegação.
contract Ballot {
     // Isso declara um novo tipo complexo que irá
     // ser usado para variáveis posteriormente.
     // Representará um único eleitor.
    struct Voter {
        uint weight; // peso é acumulado por delegação
        bool voted;  // se for verdade, essa pessoa já votou
        address delegate; // pessoa delegada a
        uint vote;   // índice da proposta votada
    }

    // Este é um tipo para uma única proposta.
    struct Proposal {
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;

    // Isso declara uma variável de estado que
    // armazena uma estrutura `Voter` para cada endereço possível.
    mapping(address => Voter) public voters;

    // Uma matriz de tamanho dinâmico de estruturas `Proposta`.
    Proposal[] public proposals;

    /// Crie uma nova cédula para escolher um dos `proposalNames`.
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // Para cada um dos nomes de proposta fornecidos,
        // cria um novo objeto de proposta e o adiciona
        // até o final da matriz.
        for (uint i = 0; i < proposalNames.length; i++) {
            // `Proposta ({...})` cria um temporário
            // Objeto de proposta e `propostas.push (...)`
            // anexa ao final de `propostas`.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // Dê ao `eleitor` o direito de votar nesta cédula.
    // Só pode ser convocado pelo `presidente`.
    function giveRightToVote(address voter) public {
        // Se o primeiro argumento de `require` avalia
        // para `false`, a execução termina e tudo
        // muda para o estado e para equilíbrios Ether
        // são revertidos.
        // Isso costumava consumir todo o gás nas versões antigas do EVM, mas
        // não mais.
        // Muitas vezes é uma boa idéia usar `require` para verificar se
        // funções são chamadas corretamente.
        // Como um segundo argumento, você também pode fornecer um
        // explicação sobre o que deu errado.
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    /// Delegar seu voto ao eleitor `a`.
    function delegate(address to) public {
        // atribui referência
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");

        require(to != msg.sender, "Self-delegation is disallowed.");

        // Encaminhe a delegação enquanto
        // `to` também delegado.
        // Em geral, esses loops são muito perigosos,
        // porque se eles correrem muito tempo, eles podem
        // precisa de mais gás do que o disponível em um bloco.
        // Neste caso, a delegação não será executada,
        // mas em outras situações, esses loops podem
        // faz com que um contrato fique completamente "preso".
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // Encontramos um loop na delegação, não permitido.
            require(to != msg.sender, "Found loop in delegation.");
        }

        // Uma vez que `sender` é uma referência, este
        // modifica `voters [msg.sender] .voted`
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // Se o delegado já votou,
            // adiciona diretamente ao número de votos
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // Se o delegado não votou ainda,
            // adicione ao peso dela.
            delegate_.weight += sender.weight;
        }
    }

    /// Dê o seu voto (incluindo votos delegados a você)
    /// para a proposta `propostas [proposta] .nome`.
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        // Se a `proposta` estiver fora do intervalo da matriz,
        // isso vai lançar automaticamente e reverter todos
        // alterar.
        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev Calcula a proposta vencedora levando todos
    /// votos anteriores em conta.
    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // Chama a função winProposal () para obter o índice
    // do vencedor contido na matriz de propostas e então
    // retorna o nome do vencedor
    function winnerName() public view
            returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}
