import { Row, Col } from "react-bootstrap";
import { useEffect, useState } from "react";

import Chain from "../network/aptos";
import tools from "../lib/tools";

function Market(props) {
    const size = {
        row: [12],
        list:[4],
    };

    let [loading, setLoading]=useState(true);
    let [list,setList]=useState([]);

    const self={
        getSelling:(ck)=>{
            const hash="0xa69ddda382a348869159f1ed42eb2fd978a5a9b5e741a5f144be4b2ff9ffd069";
            const mod="::birds_nft::queryTable";
            Chain.view([hash,mod],"view",(res)=>{
                if(!res || !res[0]) return [];
                return ck && ck(res[0]);
            })
        }
    }
    useEffect(() => {
        self.getSelling((arr)=>{
            setLoading(false);
            setList(arr);
        });
    }, [props.update]);

    return (
        <Row className="pt-2">
            <Col hidden={!loading} sm={size.row[0]} xs={size.row[0]}>
                <h5>Loading...</h5>
            </Col>
            <Col hidden={loading} sm={size.row[0]} xs={size.row[0]}>
                <Row>
                {list.map((row, index) => (
                    <Col className="pt-2" key={index} sm={size.list[0]} xs={size.list[0]} onClick={(ev) => {
                        self.clickSingle(index);
                    }}>
                        <Row>
                            <Col className="" sm={size.row[0]} xs={size.row[0]}>
                                <img className="mine" src="image/logo.png" alt="" />
                            </Col>
                            <Col className="" sm={size.row[0]} xs={size.row[0]}>
                                {tools.shorten(row,5)}
                            </Col>
                        </Row>
                    </Col>
                ))}

                </Row>
            </Col>
        </Row>
    )
}

export default Market;