## Integrantes

| Nome                                | RA                 |
|--------------------------------------|-------------------|
| Gustavo Ferreira Melo                | 2041382521009     |
| Luiz Fabiano Pereira Santana         | 2041382521026     |
| Victor Ramon Dias e Silva            | 2041382521010     |

## Ambiente AWS
Integrante dono da conta: Gustavo Ferreira Melo  
RA do dono da conta: 2041382521009
ID da conta AWS : 013482597884
Região: us-east-1
Laboratorio: 197976

## Respostas

## Enucidado 2
- (a) Quantidade de linhas de dados: 9800 linhas. 
- (b) Formato das datas: dd/mm/yyyy. Justificativa: e acordo com o item do ID 14 conseguimos identificar que as colunas Order Date e Ship Date estão seguindo a ordem dia, mês e ano. 
- (c) Linhas sem código postal: 11 linhas. 
- (d) Exemplo de produto com vírgula: "Hon Deluxe Fabric Upholstered Stacking Chairs, Rounded Back". Explicação: A vírgula não separa colunas pois o nome do produto está delimitado por aspas duplas

### Enunciado 4 — Regras do Grupo de Segurança do RDS 
Regra 1 (Porta 5432 / Meu IP): Permite conexões externas diretas ao PostgreSQL a partir do IP autorizado (ex.: conexões via psql no CloudShell ou clientes SQL locais). Sintoma de ausência: Tentativas de conexão externa ficam travadas em timeout (tempo limite esgotado) sem conseguir alcançar o banco.
Regra 2 (Porta 5432 / Próprio Security Group): Autoriza o tráfego interno dentro da VPC entre recursos que compartilham o mesmo Security Group (como os endpoints de interface e o AWS Glue). Sintoma de ausência: O teste de conexão JDBC do AWS Glue 
 

 ### Enunciado 6 — Endpoints da VPC
O Amazon S3 utiliza um endpoint Gateway porque permite o acesso privado aos buckets por meio das tabelas de rotas da VPC, sem necessidade de NAT Gateway e sem custo adicional pelo endpoint.
O AWS STS e o Secrets Manager utilizam endpoints Interface porque disponibilizam seus serviços por meio de interfaces de rede privadas dentro da VPC, utilizando AWS PrivateLink.
O DNS privado permite que os endereços habituais desses serviços sejam resolvidos para os endereços IP privados dos endpoints.
Se o DNS privado estiver desabilitado, o job do AWS Glue poderá tentar acessar os endpoints públicos. Como a rede do projeto não utiliza NAT Gateway, essas chamadas poderão falhar por falta de conectividade, impedindo a obtenção de credenciais temporárias ou o acesso às credenciais do banco.

### Enunciado 7 — Tipos inferidos pelo crawler
row id: bigint, O crawler identificou números inteiros e atribuiu um tipo inteiro de 64 bits.

postal code: bigint, O crawler interpretou os valores como numéricos. Entretanto, códigos postais são identificados e devem ser armazenados como texto para preservar zeros à esquerda e representar ausências.

sales: double, O crawler identificou valores decimais de ponto flutuante, Na staging, os valores monetários serão convertidos para NUMERIC(12,2), garantindo precisão decimal de duas casas.