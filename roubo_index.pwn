//sistema desenvolvido por zx
//contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests para melhorias ou correções.

#include <YSI_Coding\y_hooks>

#define MAX_ROUBOS 35

static enum E_ROUBOS {
    E_ROUBO_DB_ID,
    E_ROUBO_NOME[24],
    Float:E_ROUBO_POSICAO[3],
    E_ROUBO_DINHEIRO,
    E_ROUBO_INTERIOR,
    E_ROUBO_WORLD,
    Text3D:E_ROUBO_TEXTLABEL,
    E_ROUBO_PICKUP,
    E_ROUBO_DATA_CRIACAO[20], 
    E_ROUBO_TOTAL_ROUBOS,    
    E_ROUBO_ULTIMO_ROUBO[20]      
};

new static e_Roubo[MAX_ROUBOS][E_ROUBOS];

new Float:XPOS,
    Float:YPOS, 
    Float:ZPOS,
    roubo_index[MAX_PLAYERS];

hook OnGameModeInit()
    return Carregar_Roubos();

static stock Roubo_SetarPosicao(index, nome[24], valor, Float:x, Float:y, Float:z, interior, world, bool:LoadQuery = true) {

    if (index < 0 || index >= MAX_ROUBOS) 
        return false;

    Roubo_DeletarInfo(index);

    e_Roubo[index][E_ROUBO_POSICAO][0] = x;
    e_Roubo[index][E_ROUBO_POSICAO][1] = y;
    e_Roubo[index][E_ROUBO_POSICAO][2] = z;
    e_Roubo[index][E_ROUBO_DINHEIRO] = valor;
    e_Roubo[index][E_ROUBO_INTERIOR] = interior;
    e_Roubo[index][E_ROUBO_WORLD] = world;

    if (LoadQuery) {
        mysql_format(Conexao, query, sizeof(query), "INSERT INTO locais_roubo (Nome, Dinheiro, PosX, PosY, PosZ, Interior, World) VALUES ('%s', %d, %f, %f, %f, %d, %d)", nome, valor, x, y, z, interior, world);
        mysql_query(Conexao, query);
    
        e_Roubo[index][E_ROUBO_DB_ID] = cache_insert_id(); 
        printf("ID do novo local de roubo: %d", e_Roubo[index][E_ROUBO_DB_ID]);
    }
    Carregar_Roubos();
    return true;
}

static stock Roubo_AtualizarLocal(index, valor, bool:LoadQuery = true) {

    if (index < 0 || index >= MAX_ROUBOS) 
        return false; 

    e_Roubo[index][E_ROUBO_DINHEIRO] = valor;
    e_Roubo[index][E_ROUBO_TOTAL_ROUBOS]++;

    if (LoadQuery) {
        mysql_format(Conexao, query, sizeof(query), "UPDATE locais_roubo SET Dinheiro = %d, TotalRoubos = %d WHERE ID = %d", valor, e_Roubo[index][E_ROUBO_TOTAL_ROUBOS], e_Roubo[index][E_ROUBO_DB_ID]);
        mysql_query(Conexao, query);
    }

    UpdateDynamic3DTextLabelText(
        e_Roubo[index][E_ROUBO_TEXTLABEL],
        0xFF0000FF,
        va_return("{FFFFFF}ID {00bfff}%d\n{ffffff}Roubo: {00bfff}%s\n{ffffff}Dinheiro: {00bfff}R$%d\n\n{ffffff}Local {9a9a9a}Roubado {ffffff}Aguarde..", index+1, e_Roubo[index][E_ROUBO_NOME], valor)
    );
    return true;
}

static stock Roubo_ObterPosicao(index, &Float:x, &Float:y, &Float:z) {

    if (index < 1 || index >= MAX_ROUBOS) 
        return false; 

    x = e_Roubo[index][E_ROUBO_POSICAO][0];
    y = e_Roubo[index][E_ROUBO_POSICAO][1];
    z = e_Roubo[index][E_ROUBO_POSICAO][2];

    return true;
}

static stock Roubo_ObterDinheiro(index) 
    return e_Roubo[index][E_ROUBO_DINHEIRO];

static stock Roubo_Deletar(index) {

    if (index < 0 || index >= MAX_ROUBOS) 
        return false;
  
    DestroyDynamic3DTextLabel(e_Roubo[index][E_ROUBO_TEXTLABEL]);
    DestroyPickup(e_Roubo[index][E_ROUBO_NOME]);

    mysql_format(Conexao, query, sizeof(query), "DELETE FROM locais_roubo WHERE ID = %d", e_Roubo[index][E_ROUBO_DB_ID]);
    mysql_query(Conexao, query);

    return true;
}
static stock Roubo_DeletarInfo(index) {

    if (index < 0 || index >= MAX_ROUBOS) 
        return false;

    DestroyDynamic3DTextLabel(e_Roubo[index][E_ROUBO_TEXTLABEL]);
    DestroyDynamicPickup(e_Roubo[index][E_ROUBO_PICKUP]);
    return true;
}

static stock Carregar_Roubos() {

    for (new i = 0; i < MAX_ROUBOS; i++) {
        Roubo_DeletarInfo(i);
    }

    mysql_query(Conexao, "SELECT * FROM locais_roubo");

    if (!cache_num_rows()) 
        return print("Nao foi possivel encontrar nada no banco de dados");

    for (new i = 0; i < cache_num_rows() && i < MAX_ROUBOS; i++) {

        cache_get_value_name_int(i, "ID", e_Roubo[i][E_ROUBO_DB_ID]);
        cache_get_value_name(i, "Nome", e_Roubo[i][E_ROUBO_NOME], 24);
        cache_get_value_name_float(i, "PosX", e_Roubo[i][E_ROUBO_POSICAO][0]);
        cache_get_value_name_float(i, "PosY", e_Roubo[i][E_ROUBO_POSICAO][1]);
        cache_get_value_name_float(i, "PosZ", e_Roubo[i][E_ROUBO_POSICAO][2]);
        cache_get_value_name_int(i, "Dinheiro", e_Roubo[i][E_ROUBO_DINHEIRO]);
        cache_get_value_name_int(i, "Interior", e_Roubo[i][E_ROUBO_INTERIOR]);
        cache_get_value_name_int(i, "World", e_Roubo[i][E_ROUBO_WORLD]);
        cache_get_value_name(i, "DataCriacao", e_Roubo[i][E_ROUBO_DATA_CRIACAO], 20);
        cache_get_value_name_int(i, "TotalRoubos", e_Roubo[i][E_ROUBO_TOTAL_ROUBOS]);

        e_Roubo[i][E_ROUBO_TEXTLABEL] = CreateDynamic3DTextLabel(va_return("{FFFFFF}ID {00bfff}%d\n{ffffff}Roubo: {00bfff}%s\n{ffffff}Dinheiro: {00bfff}R$%d\n\n{ffffff}Digite {9a9a9a}/roubar {ffffff}para iniciar um roubo", i+1, e_Roubo[i][E_ROUBO_NOME], e_Roubo[i][E_ROUBO_DINHEIRO]),
            0xFFFFFFFF, e_Roubo[i][E_ROUBO_POSICAO][0], e_Roubo[i][E_ROUBO_POSICAO][1], e_Roubo[i][E_ROUBO_POSICAO][2] + 0.5, 
            35.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, e_Roubo[i][E_ROUBO_INTERIOR], e_Roubo[i][E_ROUBO_WORLD], -1, STREAMER_3D_TEXT_LABEL_SD, -1, 0);

        e_Roubo[i][E_ROUBO_PICKUP] = CreateDynamicPickup(1274, 23, e_Roubo[i][E_ROUBO_POSICAO][0], e_Roubo[i][E_ROUBO_POSICAO][1], e_Roubo[i][E_ROUBO_POSICAO][2],
            e_Roubo[i][E_ROUBO_INTERIOR], e_Roubo[i][E_ROUBO_WORLD]);
    }
    return 1;
}
/*
                                                                                                █▀▀ █▀▀█ █▀▄▀█ █▀▀█ █▀▀▄ █▀▀▄ █▀▀█ █▀▀
                                                                                                █░░ █░░█ █░▀░█ █▄▄█ █░░█ █░░█ █░░█ ▀▀█
                                                                                                ▀▀▀ ▀▀▀▀ ▀░░░▀ ▀░░▀ ▀░░▀ ▀▀▀░ ▀▀▀▀ ▀▀▀

                                                                                                                                                                                                                                                                    */



CMD:criarroubo(playerid, params[]) {

    new nome[24], 
        Float:posX, 
        Float:posY, 
        Float:posZ, 
        valor;

    GetPlayerPos(playerid, posX, posY, posZ);

    if (sscanf(params, "s[24]d", nome, valor)) 
        return SendClientMessage(playerid, -1, "Uso: /criarroubo [nome] [valor do local]");

    for (new i = 0; i < MAX_ROUBOS; i++) {
        if (e_Roubo[i][E_ROUBO_NOME][0] == '\0') {
            printf("Criando novo local de roubo em X: %f, Y: %f, Z: %f, Interior: %d, World: %d", posX, posY, posZ, GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid));

            Roubo_SetarPosicao(i, nome, valor, posX, posY, posZ, GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid));
            return 1;
        }
    }
    SendClientMessage(playerid, -1, "Não há mais espaço para novos locais de roubo!");
    return 1;
}
CMD:roubar(playerid, params[]) {

    new Float:x, 
        Float:y,
        Float:z, 
        index = -1;

    GetPlayerPos(playerid, x, y, z);

    for (new i = 0; i < MAX_ROUBOS; i++) {
        if (e_Roubo[i][E_ROUBO_NOME][0] != '\0') { 
            if (Roubo_ObterPosicao(i, x, y, z) && IsPlayerInRangeOfPoint(playerid, 5.0, x, y, z)) {
                index = i;
                break;
            }
        }
    }

    if (index != -1) {

        new dinheiroRoubo = e_Roubo[index][E_ROUBO_DINHEIRO];

        Roubo_AtualizarLocal(index, 0);  

        GivePlayerMoney(playerid, dinheiroRoubo);

        SendClientMessage(playerid, -1, va_return("Você roubou R$%d do cofre!", dinheiroRoubo));
    } else {
        SendClientMessage(playerid, -1, "Nenhum cofre encontrado nas proximidades!");
    }

    return 1;
}

CMD:gerenciarroubo(playerid) {

    new tablist[2 * 200 + 4 + 7], 
        line[128];

    format(tablist, sizeof(tablist), "ID\tNome\tDinheiro\tTotal Roubos\tData Criação\n");

    for (new i = 0; i < MAX_ROUBOS; i++) {
        if (e_Roubo[i][E_ROUBO_NOME][0] != '\0') {
            format(line, sizeof(line), "%d\t%s\tR$%d\t%d\t%s\n",
                e_Roubo[i][E_ROUBO_DB_ID],
                e_Roubo[i][E_ROUBO_NOME],
                e_Roubo[i][E_ROUBO_DINHEIRO],
                e_Roubo[i][E_ROUBO_TOTAL_ROUBOS],
                e_Roubo[i][E_ROUBO_DATA_CRIACAO] 
            );
            strcat(tablist, line, sizeof(tablist));
        }
    }

    if (strlen(tablist) > 0) {
        Dialog_Show(playerid, DIALOG_GEN_ROUBOS, DIALOG_STYLE_TABLIST_HEADERS, "Gerenciar Locais de Roubo", tablist, "Selecionar", "Fechar");
    } else {
        SendClientMessage(playerid, -1, "Nenhum local de roubo encontrado!");
    }

    return 1;
}
Dialog:DIALOG_GEN_ROUBOS(playerid, response, listitem, inputtext[]) {

    if (!response) return true;

    new index = -1, 
        count = 0;

    for (new i = 0; i < MAX_ROUBOS; i++) {
        if (e_Roubo[i][E_ROUBO_NOME][0] != '\0') {
            if (count == listitem) {
                if (e_Roubo[i][E_ROUBO_DB_ID] == 0) { 
                    SendClientMessage(playerid, -1, "Erro: Local com ID inválido.");
                    return true;
                }
                index = i;
                break;
            }
            count++;
        }
    }
    if (index != -1) {

        new string[2 * 235 + 10 + 15];
        roubo_index[playerid] = index;
           

        format(string, sizeof(string),
            "Nome\tInformacoes\n\
            {ffffff}ID\t{9a9a9a}%d\n\
            {ffffff}Nome\t{9a9a9a}%s\n\
            {ffffff}Dinheiro\t{9a9a9a}R$%d\n\
            {ffffff}Total Roubos\t{9a9a9a}%d\n\
            {ffffff}Data de Criacaoo\t{9a9a9a}%s\n\
            {ffffff}Interior\t{9a9a9a}%d\n\
            {ffffff}Virtual World\t{9a9a9a}%d\n\
            {ffffff}Posiçao\t{9A9A9A}%f %f %f\n\
            {ffffff}Excluir Local\t{9A9A9A}Clique para excluir",
            e_Roubo[index][E_ROUBO_DB_ID],
            e_Roubo[index][E_ROUBO_NOME],
            e_Roubo[index][E_ROUBO_DINHEIRO],
            e_Roubo[index][E_ROUBO_TOTAL_ROUBOS],
            e_Roubo[index][E_ROUBO_DATA_CRIACAO],
            e_Roubo[index][E_ROUBO_INTERIOR],
            e_Roubo[index][E_ROUBO_WORLD],
            e_Roubo[index][E_ROUBO_POSICAO][0],
            e_Roubo[index][E_ROUBO_POSICAO][1],
            e_Roubo[index][E_ROUBO_POSICAO][2]
        );

        Dialog_Show(playerid, D_RES_LOCAL, DIALOG_STYLE_TABLIST_HEADERS, "Detalhes do Local", string, "Selecionar", "Fechar");


    } else {

        SendClientMessage(playerid, -1, "Erro ao localizar o local selecionado.");
    }

    return true;
}
Dialog:D_RES_LOCAL(playerid, response, listitem, inputtext[]) {

    if (!response) return true;

    new index = 
        roubo_index[playerid];

    if (index == -1) 
        return SendClientMessage(playerid, -1, "Nenhum local de roubo selecionado.");

    switch (listitem) {
        case 0: {
            SendClientMessage(playerid, -1, "Não é possivel alterar esta informaçao..");
        }
        case 1: {
            Dialog_Show(playerid, D_EDITAR_NOME, DIALOG_STYLE_INPUT, "Editar Nome", "Digite o novo nome do local", "Salvar", "Cancelar");
        }
        case 2: {
            Dialog_Show(playerid, D_EDITAR_VAL, DIALOG_STYLE_INPUT, "Editar valor", "Digite o novo valor do local", "Salvar", "Cancelar");
        }
        case 3: {
            SendClientMessage(playerid, -1, "Não é possivel alterar esta informaçao..");
        }
        case 4: {
            SendClientMessage(playerid, -1, "Não é possivel alterar esta informaçao..");
        }
        case 5: {
            Dialog_Show(playerid, D_EDITAR_INT, DIALOG_STYLE_INPUT, "Editar Interior", "Digite o novo Interior do local", "Salvar", "Cancelar");
        }
        case 6: {
            Dialog_Show(playerid, D_EDITAR_WORLD, DIALOG_STYLE_INPUT, "Editar World", "Digite o novo World do local", "Salvar", "Cancelar");     
        }
        case 7: {
            GetPlayerPos(playerid, XPOS , YPOS, ZPOS);
            Dialog_Show(playerid, D_EDITAR_POS, DIALOG_STYLE_MSGBOX, "Editar Posicao", va_return("Ola {00bfff}%s\n{ffffff}Voce deseja definir o local do roubo ID {00bfff}%d {ffffff}nesta posicao?\nClique em Sim para definir a nova posiçao\n\nLocal Atual{9a9a9a}%f, %f, %f", PlayerName(playerid), index, XPOS, YPOS, ZPOS), "Sim", "Cancelar");      
        }
        case 8: {
            Roubo_Deletar(index);
        }
        default:{
            SendClientMessage(playerid, -1, "Opção inválida."), print("[DEBUG] UMA OPÇAO FOI ESCOLHIDA INVALIDA");
        }
    }
    return true;
}
Dialog:D_EDITAR_NOME(playerid, response, listitem, inputtext[]) {

    new index = roubo_index[playerid];

    if (!response || strlen(inputtext) == 0)
        return SendClientMessage(playerid, -1, "Operação cancelada ou nome inválido.");
    
    mysql_format(Conexao, query, sizeof(query), "UPDATE locais_roubo SET Nome = '%s' WHERE ID = %d", inputtext, e_Roubo[index][E_ROUBO_DB_ID]);
    mysql_query(Conexao, query);

    strmid(e_Roubo[index][E_ROUBO_NOME], inputtext, 0, strlen(inputtext), 20);


    Roubo_DeletarInfo(index);
    Carregar_Roubos() ;

    SendClientMessage(playerid, -1, va_return("Nome do local ID {00bfff}%d{ffffff} Alterado para %s", index, inputtext));
    return true;
}

Dialog:D_EDITAR_VAL(playerid, response, listitem, inputtext[]) {

    new index = 
        roubo_index[playerid],
        dinheiro = strval(inputtext); 

    if (e_Roubo[index][E_ROUBO_DB_ID] == 0) 
        return printf("Erro ao inserir no banco de dados. ID 0 retornado!");

    mysql_format(Conexao, query, sizeof(query), "UPDATE locais_roubo SET Dinheiro = %d WHERE ID = %d", dinheiro, e_Roubo[index][E_ROUBO_DB_ID]);
    mysql_query(Conexao, query);

    Roubo_DeletarInfo(index);

    Carregar_Roubos() ; 

    SendClientMessage(playerid, -1, va_return("Valor do local ID {00bfff}%d{ffffff} Alterado para {00BFFF}%d", index, dinheiro));
    return true;
}

Dialog:D_EDITAR_POS(playerid, response, listitem) {

    new index = 
        roubo_index[playerid];

    mysql_format(Conexao, query, sizeof(query), "UPDATE locais_roubo SET PosX = %f, PosY = %f, PosZ = %f WHERE ID = %d", XPOS, YPOS, ZPOS, e_Roubo[index][E_ROUBO_DB_ID]);
    mysql_query(Conexao, query);

    Roubo_DeletarInfo(index);

    Carregar_Roubos() ; 
    SendClientMessage(playerid, -1, va_return("Valor do local ID {00bfff}%d{ffffff} Alterado para as cordenadas {00BFFF}%f %f %f", index, XPOS, YPOS, ZPOS));
    return true;
}

Dialog:D_EDITAR_INT(playerid, response, listitem, inputtext[]) {

    new index = 
        roubo_index[playerid],
        interior = strval(inputtext);

    mysql_format(Conexao, query, sizeof(query), "UPDATE locais_roubo SET Interior = %d WHERE ID = %d", interior, e_Roubo[index][E_ROUBO_DB_ID]);
    mysql_query(Conexao, query);

    Carregar_Roubos();

    SendClientMessage(playerid, -1, va_return("Interior do local ID {00bfff}%d{ffffff} Alterado para {00BFFF}%d", index, interior));
    return true;
}

Dialog:D_EDITAR_WORLD(playerid, response, listitem, inputtext[]) {

    new index = 
        roubo_index[playerid],
        world = strval(inputtext); 

    mysql_format(Conexao, query, sizeof(query), "UPDATE locais_roubo SET World = %d WHERE ID = %d", world, e_Roubo[index][E_ROUBO_DB_ID]);
    mysql_query(Conexao, query);

    Carregar_Roubos();

    SendClientMessage(playerid, -1, va_return("World do local ID {00bfff}%d{ffffff} Alterado para {00BFFF}%d", index, world));
    return true;
}
