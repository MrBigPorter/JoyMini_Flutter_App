import { Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@api/common/jwt/jwt.guard';
import { CurrentUserId } from '@api/common/decorators/user.decorator';
import { LuckyDrawService } from '@api/common/lucky-draw/lucky-draw.service';
import { QueryTicketsDto } from './dto/query-tickets.dto';

@ApiTags('Client Lucky Draw')
@ApiBearerAuth()
@Controller('lucky-draw')
@UseGuards(JwtAuthGuard)
export class ClientLuckyDrawController {
  constructor(private readonly luckyDraw: LuckyDrawService) {}

  /**
   * GET /v1/lucky-draw/my-tickets
   * 当前用户的抽奖券列表
   */
  @Get('my-tickets')
  myTickets(@CurrentUserId() userId: string, @Query() dto: QueryTicketsDto) {
    return this.luckyDraw.listTickets(userId, {
      page: dto.page ?? 1,
      pageSize: dto.pageSize ?? 20,
      unusedOnly: dto.unusedOnly,
    });
  }

  /**
   * POST /v1/lucky-draw/tickets/:ticketId/draw
   * 用户点击「抽一下」
   */
  @Post('tickets/:ticketId/draw')
  draw(@CurrentUserId() userId: string, @Param('ticketId') ticketId: string) {
    return this.luckyDraw.draw(userId, ticketId);
  }

  /**
   * GET /v1/lucky-draw/my-results
   * 当前用户的历史中奖记录
   */
  @Get('my-results')
  myResults(@CurrentUserId() userId: string, @Query() dto: QueryTicketsDto) {
    return this.luckyDraw.listResults(userId, {
      page: dto.page ?? 1,
      pageSize: dto.pageSize ?? 20,
    });
  }
}
