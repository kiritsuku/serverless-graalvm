package pkg;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.fasterxml.jackson.databind.json.JsonMapper;

import java.io.IOException;
import java.io.UncheckedIOException;

public class GraalLambda implements RequestHandler<SQSEvent, Void> {
    private final JsonMapper mapper = JsonMapper.builder().build();

    @Override
    public Void handleRequest(SQSEvent event, Context context) {
        System.out.println(event);
        try {
            var msg = mapper.readValue(event.getRecords().get(0).getBody(), TestMessage.class);
            System.out.println(msg);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        return null;
    }
}
