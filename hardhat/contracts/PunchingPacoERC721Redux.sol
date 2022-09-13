// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

import "./interfaces/IWhitelist.sol";

contract PunchingPacoERC721Redux is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    ERC721Burnable,
    PaymentSplitter
{
    //contador para los tokens
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    //baseURI para cuando tengamos disponibles los datos a enlazar
    string _baseTokenURI;

    //precio del mint
    uint256 public price = 0.1 ether;
    //máximo total de tokens que se generan
    uint256 public maxSupply = 9630;

    //Instancia de la interface IWhitelist, nos ayudará a comprobar si al hacer mint
    //la dirección que llama o bien está en la whitelist ni tampoco tiene ban.
    IWhitelist whitelist;

    //
    bool public paused = false;

    modifier whenNotPaused() {
        require(paused == false);
        _;
    }

    //Events
    event NewTokenMinted(address _sender, uint256 tokenId);
    event BurnedToken(address _sender, uint256 tokenId);

    //shares para pa parte del Payment Splitter.  El _teamShares es el % y en _team
    // introducimos las wallets para el reparto.
    uint256[] private _teamShares = [50, 50];

    address[] private _team = [
        // hacer un array con las direcciones
        0xD8F13207964F733B93140DF41112aF6cF9dFf201,
        0xecb2130Ae925E2515aB3dB27af749762FC6C047F
    ];

    //constructor parametrizado, tenemos que haber desplegado el Whitelist primero.
    constructor(address whitelistContract, string memory _base)
        ERC721("PunchingPaco", "pPaco")
        PaymentSplitter(_team, _teamShares)
    {
        _baseTokenURI = _base;
        whitelist = IWhitelist(whitelistContract);
    }

    //funcion que cualquiera puede llamar siempre que cumpla las siguientes condiciones.
    function safeMint() public payable whenNotPaused {
        //busca el último num
        uint256 tokenId = _tokenIdCounter.current();
        // que no exceda el máximo total
        require(tokenId < maxSupply, "Exceed maxium Punching Pacos supply");
        // que esté en la whitelist
        require(
            whitelist.whitelistedAddresses(msg.sender),
            "You are not whitelisted"
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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function set_BaseURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    // Helper function
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
