// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

import "./interfaces/IWhitelist.sol";

contract PunchingPacoERC721 is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    AccessControl,
    ERC721Burnable,
    ReentrancyGuard,
    PaymentSplitter
{
    //contador para los tokens
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    //definimos los roles
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    //baseURI para cuando tengamos disponibles los datos a enlazar
    string _baseTokenURI;

    //precio del mint
    uint256 public price = 0.1 ether;
    //máximo total de tokens que se generan
    uint256 public maxTokens = 9630;

    //Instancia de la interface IWhitelist, nos ayudará a comprobar si al hacer mint
    //la dirección que llama o bien está en la whitelist ni tampoco tiene ban.
    IWhitelist whitelist;

    //mapping para guardar las direcciones que tienen MINTER_ROLE
    mapping(address => bool) private _isMinterRole;

    //eventos varios
    event ApprovedMinterRole(address _minter);
    event RevokedMinterRole(address _minter);
    event NewTokenMinted(address _sender, uint256 tokenId);
    event BurnedToken(address _sender, uint256 tokenId);

    //shares para pa parte del Payment Splitter.  El _teamShares es el % y en _team
    // introducimos las wallets para el reparto.
    uint256[] private _teamShares = [50, 50];

    address[] private _team = [
        // hacer un array con las direcciones
        0xD8F13207964F733B93140DF41112aF6cF9dFf201,
        0xD8F13207964F733B93140DF41112aF6cF9dFf201
    ];

    //constructor parametrizado, tenemos que haber desplegado el Whitelist primero.
    constructor(address whitelistContract)
        ERC721("PunchingPaco", "pPaco")
        PaymentSplitter(_team, _teamShares)
        ReentrancyGuard()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _baseTokenURI = _baseURI();
        whitelist = IWhitelist(whitelistContract);
    }

    //hacer métodos para que el user llame a ser MINTER_ROLe
    function approveMinterRole() public {
        //requiere que no sea todavía ese rol
        require(_isMinterRole[msg.sender] == false);
        // lo mapeamos
        _isMinterRole[msg.sender] = true;
        // y el user mismo llama a _grantRole
        _grantRole(MINTER_ROLE, msg.sender);
        //evento
        emit ApprovedMinterRole(msg.sender);
    }

    // para que el PAUSER pueda revocar acceso al minter.
    function revokeMinterRole(address _revoke) public onlyRole(PAUSER_ROLE) {
        //comprueba que está activado y le cambia el estado a false
        require(_isMinterRole[_revoke] == true);
        _isMinterRole[_revoke] = false;
        //evento
        emit RevokedMinterRole(_revoke);
    }

    //cuando tengamos alojadas las cosas pondremos la dire aquí
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://insertCID/";
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    //funcion que cualquiera puede llamar siempre que cumpla las siguientes condiciones.
    function safeMint() public payable {
        //busca el último num
        uint256 tokenId = _tokenIdCounter.current();
        // que no exceda el máximo total
        require(tokenId < maxTokens, "Exceed maxium Punching Pacos supply");
        // que esté en la whitelist
        require(
            whitelist.whitelistedAddresses(msg.sender),
            "You are not whitelisted"
        );
        // que tenga su role minter
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "You don't have MINTER_ROLE, bls call approveMinterRole() first."
        );
        // que envíe el valor correcto
        require(msg.value >= price, "Ether sent is not correct");
        //si pasa las duras pruebas incrementa +1 tokenIdCounter y se mintea finalmente la cosa.
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _baseTokenURI);
        //eventp
        emit NewTokenMinted(msg.sender, tokenId);
    }

    //funciones parte del estandar ERC721 de Openzeppelin
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
        //emitimos evento
        emit BurnedToken(msg.sender, tokenId);
    }

    //esta función es importante ya que es la que enlaza la dirección gererada concateando strings
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        // Here it checks if the length of the baseURI is greater than 0, if it is return the baseURI and attach
        // the tokenId and `.json` to it so that it knows the location of the metadata json file for a given
        // tokenId stored on IPFS
        // If baseURI is empty return an empty string
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
